"""Controller wake: start Gaming Mode with a controller gesture.

The gesture, per controller: switch it on (connect), then press Start,
then Home, within WINDOW seconds of connecting and with Home no more than
STEP seconds after Start. Any other button in between resets it. On a
match, POST to the Home Assistant webhook whose URL systemd hands over as
the credential "webhook-url"; HA turns the TV on and switches the sync box
to HDMI 3, which starts console mode.

Why this shape (measured on 2026-11-25):
  * The press that switches an 8BitDo Ultimate 2 on never reaches ixian;
    the gamepad device only appears once the controller has connected. So
    the gesture starts after the connect, and the first press that does
    arrive came about 4 s later.
  * Each controller's 2.4 GHz receiver adds its gamepad device when the
    controller connects and removes it when it switches off, so a new
    device node is a fresh connect.
  * Devices already present when this starts (ixian booting, a deploy
    restarting the unit) are not fresh connects and never trigger, so a
    reboot with a controller on doesn't switch the TV.

Only the standard library: input events are read straight from
/dev/input (struct input_event), devices are found by globbing their
stable by-id names.
"""

import glob
import os
import select
import struct
import sys
import time
import urllib.request

PATTERN = "/dev/input/by-id/*8BitDo*event-joystick"
WINDOW = 30.0  # seconds after connecting in which the gesture counts
STEP = 5.0  # seconds allowed between Start and Home
EV_KEY = 1
BTN_START = 315
BTN_MODE = 316  # Home
EVENT = struct.Struct("llHHi")


def log(message):
    print(message, flush=True)


def node_id(path):
    """Identity of the device node behind a by-id link; a reconnect makes a new node."""
    st = os.stat(path)
    return (st.st_dev, st.st_ino, st.st_rdev)


def send_webhook():
    directory = os.environ.get("CREDENTIALS_DIRECTORY", "")
    with open(os.path.join(directory, "webhook-url")) as f:
        url = f.read().strip()
    for attempt in range(1, 4):
        try:
            request = urllib.request.Request(url, data=b"", method="POST")
            with urllib.request.urlopen(request, timeout=10) as response:
                log(f"webhook sent (HTTP {response.status})")
                return
        except Exception as exc:  # network, DNS, HTTP errors alike
            log(f"webhook attempt {attempt}/3 failed: {exc}")
            time.sleep(2)
    log("webhook not sent; switch the controller off and on to try again")


class Controller:
    def __init__(self, path, fresh):
        self.path = path
        self.name = os.path.basename(path)
        self.node = node_id(path)
        self.fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
        self.connected = time.monotonic()
        self.armed = fresh
        self.start_at = None

    def close(self):
        try:
            os.close(self.fd)
        except OSError:
            pass

    def press(self, code):
        now = time.monotonic()
        if not self.armed:
            return False
        if now - self.connected > WINDOW:
            self.armed = False
            return False
        if code == BTN_START:
            self.start_at = now
            return False
        if code == BTN_MODE and self.start_at is not None and now - self.start_at <= STEP:
            self.armed = False
            return True
        self.start_at = None
        return False


def scan(controllers, fresh):
    for path in glob.glob(PATTERN):
        try:
            node = node_id(path)
        except OSError:
            continue
        current = controllers.get(path)
        if current is not None and current.node == node:
            continue
        if current is not None:
            current.close()
        try:
            controllers[path] = Controller(path, fresh)
        except OSError as exc:
            log(f"cannot open {path}: {exc}")
            continue
        state = "connected; waiting for Start then Home" if fresh else "already connected at start; ignored until it reconnects"
        log(f"{controllers[path].name}: {state}")
    for path in list(controllers):
        if not os.path.exists(path):
            log(f"{controllers[path].name}: disconnected")
            controllers.pop(path).close()


def main():
    controllers = {}
    scan(controllers, fresh=False)
    log(f"watching {PATTERN}: connect, then Start, then Home within {WINDOW:.0f}s")
    while True:
        scan(controllers, fresh=True)
        by_fd = {c.fd: c for c in controllers.values()}
        if not by_fd:
            time.sleep(0.5)
            continue
        ready, _, _ = select.select(list(by_fd), [], [], 0.5)
        for fd in ready:
            controller = by_fd[fd]
            try:
                data = os.read(fd, EVENT.size * 64)
            except OSError:
                log(f"{controller.name}: disconnected")
                controllers.pop(controller.path, None)
                controller.close()
                continue
            for offset in range(0, len(data) - EVENT.size + 1, EVENT.size):
                _, _, kind, code, value = EVENT.unpack_from(data, offset)
                if kind == EV_KEY and value == 1 and controller.press(code):
                    log(f"{controller.name}: gesture matched; asking Home Assistant for Gaming Mode")
                    send_webhook()


if __name__ == "__main__":
    sys.exit(main())
