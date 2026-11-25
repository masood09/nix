# Suspend — who may suspend ixian, and what wakes it.
#
# ixian suspends to RAM (S3, "deep"): RAM stays powered, so a wake needs no
# disk passphrase and is back in seconds. Tested on 2026-11-25: the RX 9060 XT
# resumes cleanly, and both wake sources below work from suspend.
#
# Who may suspend: only root. Steam's Deck-mode power policy suspends after an
# hour without controller input, and its power button and "Sleep" menu also
# suspend (logind leaves the power key to Steam). That used to take Strata,
# Caddy, SSH and monitoring down until someone pressed the button, so the
# console account is refused every sleep action through polkit. Root (the idle
# service, an admin with sudo) is not subject to polkit and can still suspend.
# Hibernation stays off: it would need a swap as large as RAM, and the
# encrypted disk would ask for its passphrase on every wake.
#
# What wakes ixian:
#   * Wake-on-LAN magic packets on the onboard 2.5GbE NIC (needs "PCIE Devices
#     Power On" in the BIOS, which is set). The magic packet is a broadcast on
#     ixian's VLAN.
#   * Switching an 8BitDo controller on: its 2.4 GHz receiver reconnects, and
#     that port change wakes ixian if wakeup is enabled on the receiver's hub
#     and on the root hub above it. The idle receiver itself can't send a
#     remote wakeup. The xHCI controller's own wakeup flag is on by default.
{
  config,
  lib,
  pkgs,
  ...
}: let
  consoleUser = config.homelab.desktop.gaming.user;
in {
  config = {
    systemd = {
      sleep = {
        settings = {
          Sleep = {
            AllowSuspend = "yes";
            AllowHibernation = "no";
            AllowHybridSleep = "no";
            AllowSuspendThenHibernate = "no";
          };
        };
      };
    };

    security = {
      polkit = {
        extraConfig = ''
          // ixian: the console account (Steam) may not suspend or hibernate.
          // See machines/ixian/_suspend.nix.
          polkit.addRule(function (action, subject) {
            if (subject.user === ${builtins.toJSON consoleUser} &&
                /^org\.freedesktop\.login1\.(suspend|hibernate|hybrid-sleep|suspend-then-hibernate)/.test(action.id)) {
              return polkit.Result.NO;
            }
          });
        '';
      };
    };

    services = {
      udev = {
        extraRules = ''
          # Wake-on-LAN: magic packets only, set whenever the NIC appears. An
          # ethtool call instead of a systemd .link file, which would replace
          # the default naming policy and could rename enp5s0. Matched by its
          # driver (ixian's only wired NIC is the onboard Realtek), since the
          # kernel's name is still eth0 while the rules run, and the MAC
          # address doesn't belong in this public repo.
          ACTION=="add", SUBSYSTEM=="net", DRIVERS=="r8169", RUN+="${lib.getExe pkgs.ethtool} -s $name wol g"

          # Controller wake: wakeup on the ASMedia USB 2 hubs the receivers sit
          # on, and on the USB 2 root hub of the chipset xHCI (0000:02:00.0)
          # above them. A receiver reconnecting when its controller switches
          # on is a port change on these hubs.
          ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="174c", ATTR{idProduct}=="2074", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
          ACTION=="add", SUBSYSTEM=="usb", ENV{DEVTYPE}=="usb_device", ATTR{idVendor}=="1d6b", ATTR{idProduct}=="0002", KERNELS=="0000:02:00.0", TEST=="power/wakeup", ATTR{power/wakeup}="enabled"
        '';
      };
    };
  };
}
