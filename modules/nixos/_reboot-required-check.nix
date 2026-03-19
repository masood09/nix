# Reboot-required check — hourly timer that compares the booted kernel/initrd
# with the current system closure. Creates /var/run/reboot-required when they
# differ (i.e. a nixos-rebuild switch upgraded the kernel). Used by MOTD/monitoring.
{
  lib,
  config,
  ...
}: let
  cfg = config.homelab.services.rebootRequiredCheck;
in {
  options = {
    homelab = {
      services = {
        rebootRequiredCheck = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Reboot required check";
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd = {
      timers = {
        "reboot-required-check" = {
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "0m";
            OnUnitActiveSec = "1h";
            Unit = "reboot-required-check.service";
          };
        };
      };

      services = {
        "reboot-required-check" = {
          script = ''
            #!/usr/bin/env bash

            if [[ "$(readlink /run/booted-system/{initrd,kernel,kernel-modules})" == "$(readlink /run/current-system/{initrd,kernel,kernel-modules})" ]]; then
              if [[ -f /var/run/reboot-required ]]; then
                rm /var/run/reboot-required || { echo "Failed to remove /var/run/reboot-required"; exit 1; }
              fi
            else
              echo "reboot required"
              touch /var/run/reboot-required || { echo "Failed to create /var/run/reboot-required"; exit 1; }
            fi
          '';
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
        };
      };
    };
  };
}
