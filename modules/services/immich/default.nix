# Immich — self-hosted photo/video management with ML-powered search.
# Excludes generated thumbnails and encoded video from restic backups.
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

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "immich";
    dataDir = immichCfg.dataDir;
    user = "immich";
    group = "immich";
    mode = "0750";
    mainServices = ["immich-server" "immich-machine-learning"];
    zfs = {
      enable = immichCfg.zfs.enable;
      datasetServiceName = "zfs-dataset-immich";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf immichCfg.enable {
    # ZFS dataset for dataDir
    homelab = {
      zfs = {
        datasets = {
          immich = lib.mkIf immichCfg.zfs.enable {
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
        };
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
          backup = {
            exclude = [
              "/mnt/nightly_backup/immich/backups"
              "/mnt/nightly_backup/immich/encoded-video"
              "/mnt/nightly_backup/immich/thumbs"
            ];
          };
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

    users = {
      users = {
        immich = {
          uid = immichCfg.userId;
        };
      };

      groups = {
        immich = {
          gid = immichCfg.groupId;
        };
      };
    };

    inherit (permSvc) systemd;

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !immichCfg.zfs.enable
      ) {
        persistence = {
          "/nix/persist" = {
            directories = [
              immichCfg.dataDir
            ];
          };
        };
      };
  };
}
