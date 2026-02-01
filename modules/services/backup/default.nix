{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.backup;

  unitsFile =
    pkgs.writeText "backup-service-units.txt"
    (lib.concatStringsSep "\n" cfg.serviceUnits + "\n");

  servicesStopScript = pkgs.writeShellScript "backup-stop-units" ''
    set -euo pipefail

    echo "Stopping units for backup..."

    while IFS= read -r unit; do
      [ -z "$unit" ] && continue

      load_state="$(systemctl show -p LoadState --value "$unit" 2>/dev/null || true)"

      if [ "$load_state" != "loaded" ]; then
        echo " - $unit (not installed) -> skip"
        continue
      fi

      if systemctl is-active --quiet "$unit"; then
        echo " - stopping $unit"
        systemctl stop "$unit"
      else
        echo " - $unit (not active) -> skip"
      fi
    done < ${unitsFile}
  '';
in {
  imports = [
    ./options.nix
    ./restic.nix
    ./zfs.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab.services.restic.enable = true;

    systemd = {
      services = {
        backup-system = {
          description = "Homelab backup orchestration";
          wantedBy = [];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          restartIfChanged = false;

          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = servicesStopScript;

            ExecStart = pkgs.writeShellScript "homelab-backup-run" ''
              set -euo pipefail
              echo "Running homelab backup pipeline..."

              # TODO: plug in your real steps
              # systemctl start postgresqlBackup-applysmart.service
              # systemctl start restic-zfs-prepare.service
              # systemctl start restic-backups-backup.service
              # systemctl start restic-zfs-cleanup.service

              echo "Backup pipeline complete."
            '';

            TimeoutStartSec = "6h";
          };
        };
      };

      timers."backup-system" = {
        wantedBy = ["timers.target"];
        timerConfig = {
          OnCalendar = "*-*-* 02:00:00";
        };
      };
    };
  };
}
