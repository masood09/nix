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
#
# When ixian suspends: idle-suspend.service (_idle-suspend.py, whose header
# has the rules) after 20 min without an LLM request, 1 min after game mode
# ends, or 10 min after a wake that didn't lead anywhere. It unloads Strata
# first, and sets the RTC alarm so the weekly upgrade and nix-gc run awake.
# Leaving game mode doesn't start Strata (console-mode's
# startStrataAfterGaming = false in _config.nix), so that minute is only a
# buffer, not a model load.
{
  config,
  lib,
  pkgs,
  ...
}: let
  consoleUser = config.homelab.desktop.gaming.user;
  strataCfg = config.homelab.services.strata;

  idleSuspend =
    pkgs.writers.writePython3 "idle-suspend" {
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./_idle-suspend.py);
in {
  config = {
    systemd = {
      services = {
        idle-suspend = {
          description = "Suspend ixian when idle, and set up its wake";
          wantedBy = ["multi-user.target"];
          after = ["console-mode.service" "strata.service"];
          path = [pkgs.iproute2 config.systemd.package];

          serviceConfig = {
            ExecStart = lib.escapeShellArgs [
              (toString idleSuspend)
              "--idle"
              "1200"
              "--after-gaming"
              "60"
              "--after-wake"
              "600"
              "--controller-grace"
              "60"
              "--marker"
              strataCfg.holdFile
              "--strata-url"
              "http://${strataCfg.listenAddress}:${toString strataCfg.listenPort}"
              "--ssh-port"
              (toString (lib.head config.services.openssh.ports))
              "--busy-unit"
              "nixos-upgrade.service"
              "--busy-unit"
              "nix-gc.service"
              "--wake-for"
              "nixos-upgrade.timer"
              "--wake-for"
              "nix-gc.timer"
              # Planned-suspend report for Grafana's ixian alerts (see
              # modules/services/grafana/alerting-rules.nix).
              "--status-file"
              "${toString config.homelab.services.alloy.textfileDir}/idle-suspend.prom"
            ];
            Restart = "always";
            RestartSec = 10;
          };
        };
      };

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
