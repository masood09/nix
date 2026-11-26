"""Wake ixian: send a Wake-on-LAN magic packet on ixian's VLAN.

A magic packet is six 0xff bytes followed by the target MAC sixteen times; the
NIC looks for that pattern anywhere in a frame. It is sent here as a raw
Ethernet broadcast (EtherType 0x0842) on an interface that has no IP address,
so it needs no routing and works however long ixian has been asleep (unlike a
UDP packet routed through the gateway, which needs ixian's MAC still in the
gateway's ARP cache).

Usage: wake-ixian INTERFACE  (the MAC comes from the systemd credential
"ixian-mac", so it never appears on the command line or in this public repo).
"""

import os
import socket
import sys

ETHERTYPE_WOL = b"\x08\x42"


def parse_mac(text):
    digits = text.strip().replace(":", "").replace("-", "").lower()
    mac = bytes.fromhex(digits)
    if len(mac) != 6:
        raise ValueError("a MAC address has 6 bytes")
    return mac


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: wake-ixian INTERFACE")
    interface = sys.argv[1]
    credentials = os.environ.get("CREDENTIALS_DIRECTORY", "")
    with open(os.path.join(credentials, "ixian-mac")) as f:
        target = parse_mac(f.read())
    with open(f"/sys/class/net/{interface}/address") as f:
        source = parse_mac(f.read())

    frame = b"\xff" * 6 + source + ETHERTYPE_WOL + b"\xff" * 6 + target * 16
    with socket.socket(socket.AF_PACKET, socket.SOCK_RAW) as s:
        s.bind((interface, 0))
        # A few copies: a single frame can be lost, and duplicates are harmless.
        for _ in range(3):
            s.send(frame)
    print(f"magic packet sent on {interface} (3 frames)", flush=True)


if __name__ == "__main__":
    main()
