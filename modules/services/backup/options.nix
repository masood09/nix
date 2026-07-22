# Options — backup orchestration (restic paths, ZFS snapshot + restic repo).
{lib, ...}: {
  options = {
    homelab = {
      services = {
        backup = {
          enable = lib.mkEnableOption "Whether to enable homelab backup orchestration.";

          extraPaths = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Extra filesystem paths to include in restic backup (in addition to staged ZFS snapshot views).";
          };

          backupRoot = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/nightly_backup";
            description = "Root directory where ZFS snapshots are mounted for restic backup.";
          };

          serviceUnits = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["podman-opencloud.service" "postgresql.service"];
            description = "systemd unit names to stop while snapshots/db dumps are taken.";
          };
        };

        restic = {
          enable = lib.mkEnableOption "Whether to enable restic backups.";

          check = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to verify restic repository integrity on a timer.";
            };

            readDataSubset = lib.mkOption {
              type = lib.types.str;
              default = "10%";
              example = "1/7";
              description = ''
                Fraction of repository data to download and verify, passed to
                `restic check --read-data-subset`. Metadata is always checked in
                full; this controls how much pack data is fetched from S3.
              '';
            };

            onCalendar = lib.mkOption {
              type = lib.types.str;
              default = "Sun *-*-* 04:00:00";
              description = ''
                When to run the integrity check. Defaults to weekly, between the
                nightly backup (02:00) and the weekly GC (Sun 06:00).
              '';
            };
          };

          pruneOpts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "--keep-daily 3"
              "--keep-weekly 4"
            ];

            description = "Restic forget/prune retention options passed as pruneOpts.";

            example = [
              "--keep-last 7"
            ];
          };
        };
      };
    };
  };
}
