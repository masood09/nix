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

            retryLock = lib.mkOption {
              type = lib.types.str;
              default = "1h";
              example = "0";
              description = ''
                How long to wait for the repository lock before giving up,
                passed to `restic check --retry-lock`.

                restic defaults to no retries at all, so the check fails
                outright if the nightly backup's `forget --prune` is still
                holding the lock. The two are two hours apart on paper, but a
                long backup closes that gap — heartbeat's takes over ten
                minutes before pruning even starts. Waiting is strictly better
                than failing here: nothing else is queued behind the check.

                Set to "0" to restore restic's fail-fast behaviour.
              '';
            };
          };

          pruneOpts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              # Group only by host, not the default host+paths. restic applies
              # keep-daily/keep-weekly independently per group, so with the
              # default grouping a snapshot's *path set* defines its retention
              # bucket — and any time a dataset is added or an extraPath
              # changes, the old path set stops receiving snapshots and its
              # survivors are pinned forever (keep-daily/weekly count snapshots
              # in the group, not elapsed days, so nothing ages them out).
              #
              # Each host backs up to its own repository with a single host
              # label, so grouping by host alone means retention spans path-set
              # changes: old path sets age out by time like everything else.
              "--group-by host"
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
