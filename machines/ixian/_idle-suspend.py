"""Idle suspend: put ixian to sleep when nothing needs it, and set up the wake.

Every POLL seconds it decides whether ixian is busy and how long it has been
idle, and suspends to RAM once the idle time reaches the threshold for the
current context:

  default          IDLE seconds without an LLM request (inference mode)
  after-gaming     AFTER_GAMING seconds after game mode ends, until the next
                   LLM request (then default)
  after-wake       AFTER_WAKE seconds after a wake that didn't lead anywhere
                   (a controller wake without the gesture, a scheduled wake)

Never while: game mode (console-mode's marker file), an LLM request in
flight, an SSH session, a listed unit active (the weekly upgrade, nix-gc),
or a logind "block" inhibitor on sleep.

Before suspending it stops Strata and model-router (a loaded model holds
~52 GB of RAM and ~15 GB of VRAM, and amdgpu would have to save the VRAM into
RAM that isn't there), and sets the RTC alarm a few minutes before the next
run of each scheduled unit, so those run while awake.

After any resume (its own suspend or someone else's) it works out the cause:
  * a controller connected within CONTROLLER_SETTLE s: wait CONTROLLER_GRACE s
    for game mode; if it doesn't come, start Strata and use after-wake;
  * the RTC alarm it set: don't start Strata, use after-wake;
  * anything else (Wake-on-LAN, the power button): start Strata, use default.

Only the standard library; logind and systemd are driven through their
command-line tools.
"""

import argparse
import glob
import json
import os
import subprocess
import sys
import time
import urllib.request

GAMEPADS = "/dev/input/by-id/*8BitDo*event-joystick"
RTC_ALARM = "/sys/class/rtc/rtc0/wakealarm"


def log(message):
    print(message, flush=True)


def run(*argv):
    return subprocess.run(argv, capture_output=True, text=True, check=False)


def gamepad_nodes():
    """Identities of the connected gamepads' device nodes; a reconnect makes a new one."""
    nodes = set()
    for path in glob.glob(GAMEPADS):
        try:
            st = os.stat(path)
            nodes.add((st.st_dev, st.st_ino))
        except OSError:
            pass
    return nodes


def suspended_seconds():
    """Seconds spent suspended since boot (BOOTTIME keeps counting in S3, MONOTONIC doesn't)."""
    return time.clock_gettime(time.CLOCK_BOOTTIME) - time.clock_gettime(time.CLOCK_MONOTONIC)


class Idle:
    def __init__(self, args):
        self.a = args
        self.context = "default"
        self.idle_since = time.time()
        self.last_busy = None
        self.was_gaming = self.gaming()
        self.slept = suspended_seconds()
        self.alarm_at = None
        self.pads_before = set()
        self.last_report = 0.0

    # --- what ixian is doing -------------------------------------------------

    def gaming(self):
        return os.path.exists(self.a.marker)

    def strata_activity(self):
        """(in_flight, last_request_at) from Strata, or (0, None) when it isn't answering."""
        try:
            with urllib.request.urlopen(self.a.strata_url + "/v1/status", timeout=3) as r:
                activity = json.load(r).get("activity") or {}
            return int(activity.get("in_flight") or 0), activity.get("last_request_at")
        except Exception:
            return 0, None

    def busy_reasons(self):
        reasons = []
        if self.gaming():
            reasons.append("game mode")
        out = run("ss", "-Htn", "state", "established", "sport", "=", f":{self.a.ssh_port}").stdout
        if out.strip():
            reasons.append(f"{len(out.strip().splitlines())} SSH connection(s)")
        for unit in self.a.busy_unit:
            if run("systemctl", "is-active", "--quiet", unit).returncode == 0:
                reasons.append(unit)
        due = self.next_scheduled()
        if due is not None and due - time.time() < self.a.wake_early + 120:
            reasons.append(f"scheduled job due at {time.strftime('%H:%M', time.localtime(due))}")
        for line in run("systemd-inhibit", "--list", "--no-legend", "--no-pager").stdout.splitlines():
            cols = line.split()
            if len(cols) >= 2 and cols[-1] == "block" and "sleep" in line:
                reasons.append(f"sleep inhibitor ({cols[0]})")
        in_flight, last_request = self.strata_activity()
        if in_flight:
            reasons.append(f"{in_flight} LLM request(s) in flight")
        if last_request:
            self.note_request(float(last_request))
        return reasons

    def note_request(self, when):
        """An LLM request newer than the idle timer restarts it, at the default threshold."""
        if when <= self.idle_since:
            return
        self.idle_since = when
        if self.context != "default":
            log(f"LLM request: idle threshold back to {self.a.idle}s")
            self.context = "default"

    def threshold(self):
        return {
            "default": self.a.idle,
            "after-gaming": self.a.after_gaming,
            "after-wake": self.a.after_wake,
        }[self.context]

    # --- suspend and wake ----------------------------------------------------

    def next_scheduled(self):
        """Earliest next run (epoch s) of the scheduled timers, or None."""
        times = []
        for timer in self.a.wake_for:
            out = run("systemctl", "show", timer, "-p", "NextElapseUSecRealtime", "--timestamp=unix", "--value").stdout.strip()
            if out.startswith("@"):
                times.append(float(out[1:]))
        future = [t for t in times if t > time.time() + 60]
        return min(future) if future else None

    def set_alarm(self):
        when = self.next_scheduled()
        self.alarm_at = None
        try:
            with open(RTC_ALARM, "w") as f:
                f.write("0")
            if when is not None:
                at = int(max(when - self.a.wake_early, time.time() + 60))
                with open(RTC_ALARM, "w") as f:
                    f.write(str(at))
                self.alarm_at = at
                log(f"RTC alarm set for {time.strftime('%a %H:%M', time.localtime(at))} (next scheduled job)")
        except OSError as exc:
            log(f"could not set the RTC alarm: {exc}")

    def write_status(self, suspended, expected_wake=0):
        """Tell monitoring (Alloy's textfile collector) that the suspend is planned.

        Grafana mutes the "ixian silent" alert while the last report says
        suspended, and alerts if a planned wake is overdue.
        """
        if not self.a.status_file:
            return
        text = (
            "# HELP node_suspended 1 while idle-suspend has put this host to sleep on purpose.\n"
            "# TYPE node_suspended gauge\n"
            f"node_suspended {1 if suspended else 0}\n"
            "# HELP node_suspend_expected_wake_timestamp_seconds RTC wake set for the current suspend, 0 if none.\n"
            "# TYPE node_suspend_expected_wake_timestamp_seconds gauge\n"
            f"node_suspend_expected_wake_timestamp_seconds {int(expected_wake)}\n"
        )
        tmp = self.a.status_file + ".tmp"
        try:
            with open(tmp, "w") as f:
                f.write(text)
            os.chmod(tmp, 0o644)
            os.replace(tmp, self.a.status_file)
        except OSError as exc:
            log(f"could not write the monitoring status: {exc}")

    def suspend(self, idle_for):
        log(f"idle {idle_for:.0f}s ({self.context}, threshold {self.threshold()}s): stopping Strata and suspending")
        if self.a.dry_run:
            log("dry run: not suspending")
            self.idle_since = time.time()
            return
        # Report the planned suspend first and give Alloy time to ship it
        # (10 s scrape plus remote write), still serving and still watching:
        # anything that starts in the meantime cancels the suspend.
        due = self.next_scheduled()
        expected = int(max(due - self.a.wake_early, time.time() + 60)) if due is not None else 0
        self.write_status(True, expected)
        deadline = time.monotonic() + self.a.report_wait
        while time.monotonic() < deadline:
            time.sleep(min(5, max(0.0, deadline - time.monotonic())))
            reasons = self.busy_reasons()
            if reasons or self.idle_since > time.time() - 60:
                log("suspend cancelled: " + (", ".join(reasons) or "LLM request"))
                self.write_status(False)
                self.idle_since = max(self.idle_since, time.time())
                return
        stop = run("systemctl", "stop", "strata.service", "model-router.service")
        if stop.returncode != 0:
            log(f"stopping Strata failed ({stop.stderr.strip()}); not suspending")
            self.write_status(False)
            self.idle_since = time.time()
            return
        self.set_alarm()
        self.pads_before = gamepad_nodes()
        before = suspended_seconds()
        result = run("systemctl", "suspend")
        if result.returncode != 0:
            log(f"suspend refused: {result.stderr.strip()}")
            self.write_status(False)
            self.start_strata("suspend failed")
            self.idle_since = time.time()
            return
        deadline = time.monotonic() + 60
        while suspended_seconds() - before < 1 and time.monotonic() < deadline:
            time.sleep(0.5)
        if suspended_seconds() - before < 1:
            # The request went through but the machine never slept: don't
            # leave monitoring believing it did.
            log("suspend requested but ixian didn't sleep within 60s")
            self.write_status(False)
            self.start_strata("suspend didn't happen")
            self.idle_since = time.time()

    def start_strata(self, why):
        if self.gaming():
            return
        log(f"starting Strata ({why})")
        run("systemctl", "start", "strata.service", "model-router.service")

    def resumed(self, slept_for):
        woke = time.time()
        self.write_status(False)
        log(f"resumed after {slept_for:.0f}s asleep")
        if self.alarm_at is not None and abs(woke - self.alarm_at) < 180:
            self.context, self.idle_since = "after-wake", woke
            log(f"woken by the RTC alarm for a scheduled job; Strata stays stopped, threshold {self.a.after_wake}s once the job is done")
        else:
            # Only a gamepad device that is new since the suspend counts: a
            # controller left on through it doesn't mean it woke ixian.
            settle = time.monotonic() + self.a.controller_settle
            while not (gamepad_nodes() - self.pads_before) and time.monotonic() < settle:
                time.sleep(0.5)
            if gamepad_nodes() - self.pads_before:
                log(f"woken by a controller; waiting {self.a.controller_grace}s for game mode")
                grace = time.monotonic() + self.a.controller_grace
                while not self.gaming() and time.monotonic() < grace:
                    time.sleep(1)
                if self.gaming():
                    log("game mode started")
                else:
                    self.start_strata("controller wake without the gesture")
                    self.context, self.idle_since = "after-wake", time.time()
            else:
                self.start_strata("woken over the network or by hand")
                self.context, self.idle_since = "default", time.time()
        self.alarm_at = None
        self.pads_before = set()
        try:
            with open(RTC_ALARM, "w") as f:
                f.write("0")
        except OSError:
            pass
        self.was_gaming = self.gaming()
        self.last_busy = None

    # --- main loop -----------------------------------------------------------

    def step(self):
        now = time.time()
        slept = suspended_seconds()
        if slept - self.slept > 5:
            gap = slept - self.slept
            self.slept = slept
            self.resumed(gap)
            return
        self.slept = slept

        gaming = self.gaming()
        if self.was_gaming and not gaming:
            self.context, self.idle_since = "after-gaming", now
            log(f"game mode ended: suspending after {self.a.after_gaming}s without an LLM request")
        self.was_gaming = gaming

        reasons = self.busy_reasons()
        if reasons:
            self.idle_since = max(self.idle_since, now)
            if reasons != self.last_busy:
                log("awake: " + ", ".join(reasons))
            self.last_busy = reasons
            return
        if self.last_busy:
            log("nothing keeps ixian awake; idle timer running")
        self.last_busy = None

        idle_for = now - self.idle_since
        if idle_for >= self.threshold():
            self.suspend(idle_for)
        elif now - self.last_report >= 300:
            log(f"idle {idle_for:.0f}s of {self.threshold()}s ({self.context})")
            self.last_report = now


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--idle", type=int, default=1200)
    p.add_argument("--after-gaming", type=int, default=300)
    p.add_argument("--after-wake", type=int, default=600)
    p.add_argument("--controller-grace", type=int, default=60)
    p.add_argument("--controller-settle", type=float, default=8.0)
    p.add_argument("--poll", type=float, default=15.0)
    p.add_argument("--marker", required=True)
    p.add_argument("--strata-url", default="http://127.0.0.1:8916")
    p.add_argument("--ssh-port", type=int, default=22)
    p.add_argument("--busy-unit", action="append", default=[])
    p.add_argument("--wake-for", action="append", default=[], help="timer whose next run gets an RTC wake")
    p.add_argument("--wake-early", type=int, default=300, help="seconds before the timer to wake")
    p.add_argument("--status-file", help="textfile-collector .prom file to report a planned suspend in")
    p.add_argument("--report-wait", type=float, default=30.0, help="seconds between reporting a suspend and doing it")
    p.add_argument("--dry-run", action="store_true")
    args = p.parse_args()

    idle = Idle(args)
    idle.write_status(False)
    mode = " (dry run)" if args.dry_run else ""
    log(
        f"idle suspend: {args.idle}s idle, {args.after_gaming}s after game mode, "
        f"{args.controller_grace}s grace + {args.after_wake}s after a wake{mode}"
    )
    while True:
        try:
            idle.step()
        except Exception as exc:  # keep running; the next poll tries again
            log(f"error: {exc}")
        time.sleep(args.poll)


if __name__ == "__main__":
    sys.exit(main())
