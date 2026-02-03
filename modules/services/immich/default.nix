{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  immichCfg = homelabCfg.services.immich;
  postgresqlEnabled = config.homelab.services.postgresql.enable;
  postgresqlBackupEnabled = config.homelab.services.postgresql.backup.enable;
  caddyEnabled = config.homelab.services.caddy.enable;
  resticEnabled = config.homelab.services.restic.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf immichCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.immich = lib.mkIf immichCfg.zfs.enable {
      inherit (immichCfg.zfs) dataset properties;

      enable = true;
      mountpoint = immichCfg.dataDir;

      requiredBy = [
        "immich-server.service"
        "immich-machine-learning.service"
      ];

      restic = {
        enable = true;
      };
    };

    services = {
      immich = {
        inherit (immichCfg) enable;

        mediaLocation = immichCfg.dataDir;

        database = {
          enable = postgresqlEnabled;
          enableVectors = false;
        };
      };

      restic = lib.mkIf (resticEnabled && immichCfg.zfs.enable) {
        backups = {
          backup.exclude = [
            "/mnt/nightly_backup/immich/backups"
            "/mnt/nightly_backup/immich/encoded-video"
            "/mnt/nightly_backup/immich/thumbs"
          ];
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${immichCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.immich.port}
            '';
          };
        };
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled) {
        databases = [
          config.services.immich.database.name
        ];
      };
    };

    users.users = {
      immich.uid = immichCfg.userId;
    };

    users.groups = {
      immich.gid = immichCfg.groupId;
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        immich-server = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [immichCfg.dataDir];
            };
          }

          (lib.mkIf immichCfg.zfs.enable {
            requires = ["zfs-dataset-immich.service"];
            after = ["zfs-dataset-immich.service"];
          })
        ];

        immich-machine-learning = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [immichCfg.dataDir];
            };
          }

          (lib.mkIf immichCfg.zfs.enable {
            requires = ["zfs-dataset-immich.service"];
            after = ["zfs-dataset-immich.service"];
          })
        ];

        immich-permissions = {
          description = "Fix Immich dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = [
            "immich-server.service"
            "immich-machine-learning.service"
          ];
          after =
            ["local-fs.target"]
            ++ lib.optionals immichCfg.zfs.enable [
              "zfs-dataset-immich.service"
            ];
          requires = lib.optionals immichCfg.zfs.enable [
            "zfs-dataset-immich.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown immich:immich ${toString immichCfg.dataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${immichCfg.dataDir} 0750 immich immich -"
        "z ${immichCfg.dataDir} 0750 immich immich -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !immichCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          immichCfg.dataDir
        ];
      };
  };
}
