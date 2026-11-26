"""Game state: tell Home Assistant whether a game is being played.

States, sent as JSON {"state", "app_id", "name"} to the Home Assistant
webhook whose URL systemd hands over as the credential "webhook-url":

  none     no game running
  playing  a game runs and is in front
  paused   a game runs, but the Steam menu is in front of it

"paused" is what the Steam button opens over a game. The game does not
stop underneath: cutscenes and gameplay keep running (measured on
2026-11-26 in Red Dead Redemption 2). A game's own pause menu cannot be
seen from outside.

Signals (measured on 2026-11-26):
  * Steam starts every game, Steam titles and the gamectl tiles alike,
    through a "reaper SteamLaunch AppId=<id>" process, which lives as long
    as the game does.
  * gamescope publishes the app in front as GAMESCOPE_FOCUSED_APP on the
    root window of its Xwayland display :0: the game's AppID while it is in
    front, 769 (Steam's UI) when the Steam menu is open. The console user
    reaches the display without an Xauthority.
  * Between launch and its first frame the game is not yet in front (16 s
    for RDR2), which would read as "paused". It stays "none" until the game
    has been in front once.

Names: Steam titles from steamapps/appmanifest_<id>.acf, gamectl tiles
and other shortcuts from userdata/*/config/shortcuts.vdf (binary VDF,
whose appid field is a signed 32-bit integer).

Only changes are sent, and the current state again whenever the service
starts, so Home Assistant catches up after a boot or a restart. A send
that fails is retried on the next poll.
"""

import glob
import json
import os
import re
import subprocess
import sys
import time
import urllib.request

import vdf

POLL = 2.0  # seconds between checks
ATTEMPT_TIMEOUT = 3.0  # seconds per webhook attempt
STEAM_UI = 769
DISPLAY = ":0"
LAUNCH = re.compile(rb"SteamLaunch\0AppId=(\d+)\0")
STEAM_ROOT = os.path.expanduser("~/.local/share/Steam")
XPROP = sys.argv[1] if len(sys.argv) > 1 else "xprop"


def log(message):
    print(message, flush=True)


def running_game():
    """AppID of the game Steam launched, or None."""
    for cmdline in glob.glob("/proc/[0-9]*/cmdline"):
        try:
            with open(cmdline, "rb") as f:
                match = LAUNCH.search(f.read())
        except OSError:
            continue
        if match:
            return int(match.group(1))
    return None


def focused_app():
    """GAMESCOPE_FOCUSED_APP on display :0, or None if it can't be read."""
    try:
        out = subprocess.run(
            [XPROP, "-display", DISPLAY, "-root", "GAMESCOPE_FOCUSED_APP"],
            capture_output=True, text=True, timeout=5,
        ).stdout
    except (OSError, subprocess.TimeoutExpired):
        return None
    match = re.search(r"=\s*(\d+)", out)
    return int(match.group(1)) if match else None


def game_name(app_id):
    """The game's name from Steam's library or its shortcuts, or ''."""
    manifest = os.path.join(STEAM_ROOT, "steamapps", f"appmanifest_{app_id}.acf")
    try:
        with open(manifest) as f:
            return vdf.load(f).get("AppState", {}).get("name", "")
    except (OSError, SyntaxError):
        pass
    for path in glob.glob(os.path.join(STEAM_ROOT, "userdata", "*", "config", "shortcuts.vdf")):
        try:
            with open(path, "rb") as f:
                shortcuts = vdf.binary_load(f).get("shortcuts", {})
        except (OSError, SyntaxError, ValueError):
            continue
        for entry in shortcuts.values():
            if (entry.get("appid", 0) & 0xFFFFFFFF) == app_id:
                return entry.get("AppName") or entry.get("appname") or ""
    return ""


def send(url, report):
    """POST the report; True once Home Assistant accepted it."""
    request = urllib.request.Request(
        url,
        data=json.dumps(report).encode(),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=ATTEMPT_TIMEOUT) as response:
            return 200 <= response.status < 300
    except Exception as exc:  # network, DNS, HTTP errors alike
        log(f"webhook failed ({exc}); retrying on the next check")
        return False


def main():
    directory = os.environ.get("CREDENTIALS_DIRECTORY", "")
    with open(os.path.join(directory, "webhook-url")) as f:
        url = f.read().strip()

    names = {}
    seen_in_front = set()
    sent = None
    while True:
        app_id = running_game()
        if app_id is None:
            seen_in_front.clear()
            report = {"state": "none", "app_id": None, "name": ""}
        else:
            focus = focused_app()
            if focus == app_id:
                seen_in_front.add(app_id)
            if app_id not in seen_in_front:
                report = {"state": "none", "app_id": None, "name": ""}
            else:
                if app_id not in names:
                    names[app_id] = game_name(app_id)
                state = "playing" if focus == app_id else "paused"
                report = {"state": state, "app_id": app_id, "name": names[app_id]}

        if report != sent and send(url, report):
            label = f" {report['name'] or report['app_id']}" if report["app_id"] else ""
            log(f"{report['state']}{label}")
            sent = report
        time.sleep(POLL)


if __name__ == "__main__":
    main()
