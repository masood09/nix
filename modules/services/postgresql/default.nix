{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  postgresqlCfg = homelabCfg.services.postgresql;
  backupCfg = postgresqlCfg.backup;
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf postgresqlCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.postgresql = lib.mkIf postgresqlCfg.zfs.enable {
      inherit (postgresqlCfg.zfs) dataset properties;

      enable = true;
      mountpoint = postgresqlCfg.dataDir;
      requiredBy = ["postgresql.service"];
    };

    # ZFS dataset for backup dataDir
    homelab.zfs.datasets.postgresql-backup =
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

      prometheus.exporters.postgres = {
        enable = true;
        listenAddress = "127.0.0.1";
        runAsLocalSuperUser = true;
      };
    };

    # Service hardening + mount ordering
    systemd.services = {
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

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !postgresqlCfg.zfs.enable
      )
      {
        persistence."/nix/persist".directories = [
          postgresqlCfg.dataDir
        ];
      };

    networking.firewall.allowedTCPPorts =
      lib.mkIf (
        postgresqlCfg.enable
        && config.services.postgresql.enableTCPIP
      )
      [
        config.services.postgresql.settings.port
      ];
  };
}
