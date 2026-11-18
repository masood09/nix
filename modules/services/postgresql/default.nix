# PostgreSQL — shared database server. Peer auth only (no passwords); each
# service gets its own DB via ensureDatabases. Includes Prometheus exporter
# and optional nightly pg_dump backups to a separate ZFS dataset.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  postgresqlCfg = homelabCfg.services.postgresql;
  backupCfg = postgresqlCfg.backup;
  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
in {
  imports = [
    ./alloy.nix
    ./collation-check.nix
    ./options.nix
  ];

  config = lib.mkIf postgresqlCfg.enable {
    # ZFS dataset for dataDir
    homelab = {
      zfs = {
        datasets = {
          postgresql = lib.mkIf postgresqlCfg.zfs.enable {
            inherit (postgresqlCfg.zfs) dataset properties;

            enable = true;
            mountpoint = postgresqlCfg.dataDir;
            requiredBy = ["postgresql.service"];

            # The live data directory is the PostgreSQL backup: every database
            # on the host, snapshotted in the same atomic call as every other
            # service dataset, so it is consistent with the blobs those
            # services reference. Restoring it is equivalent to recovering
            # from a power cut, which is exactly what pg_basebackup and PITR
            # already rely on — pg_wal lives inside $PGDATA, and $PGDATA is
            # this dataset's mountpoint, so the WAL is inside the same
            # snapshot.
            #
            # Nightly pg_dump (backup.enable, below) is off fleet-wide: the
            # dump's one advantage, portability across PostgreSQL major
            # versions or rolling back a single database, is needed only
            # before a planned upgrade, so take a dump by hand then. See
            # docs/backup.org.
            restic = {
              enable = true;
            };
          };

          # ZFS dataset for backup dataDir
          postgresql-backup =
            lib.mkIf (
              backupCfg.enable
              && backupCfg.zfs.enable
            )
            {
              inherit (backupCfg.zfs) dataset properties;

              enable = true;
              mountpoint = backupCfg.dataDir;
              requiredBy = ["postgresql.service"];

              restic = {
                enable = true;
              };
            };
        };
      };
    };

    services = {
      postgresql = {
        inherit (postgresqlCfg) enable enableTCPIP package dataDir;

        authentication = lib.mkDefault ''
          # TYPE  DATABASE        USER            ADDRESS                 METHOD

          # postgres can connect ONLY via Unix socket
          local   all             postgres                                peer
          host    all             postgres        127.0.0.1/32            reject
          host    all             postgres        ::1/128                 reject
          host    all             postgres        0.0.0.0/0               reject

          # Other local users via Unix socket (no password), but ONLY to DB with same name as user
          local   sameuser        all                                     peer
        '';
      };

      postgresqlBackup = lib.mkIf backupCfg.enable {
        inherit (backupCfg) enable;

        location = backupCfg.dataDir;
        pgdumpOptions = "--no-owner";
        startAt = "2000-01-01 00:00";
      };

      prometheus = {
        exporters = {
          postgres = {
            enable = true;
            listenAddress = "127.0.0.1";
            runAsLocalSuperUser = true;
          };
        };
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        postgresql = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [postgresqlCfg.dataDir];
            };
          }

          (lib.mkIf postgresqlCfg.zfs.enable {
            requires = ["zfs-dataset-postgresql.service"];
            after = ["zfs-dataset-postgresql.service"];
          })

          (lib.mkIf (backupCfg.enable && backupCfg.zfs.enable) {
            requires = ["zfs-dataset-postgresql-backup.service"];
            after = ["zfs-dataset-postgresql-backup.service"];
          })
        ];
      };
    };

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = postgresqlCfg.zfs.enable;
      directories = [postgresqlCfg.dataDir];
    };

    networking = {
      firewall = {
        allowedTCPPorts =
          lib.mkIf (
            postgresqlCfg.enable
            && config.services.postgresql.enableTCPIP
          )
          [
            config.services.postgresql.settings.port
          ];
      };
    };
  };
}
