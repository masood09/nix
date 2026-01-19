{
  config,
  lib,
  ...
}: let
  immichCfg = config.homelab.services.immich;
  postgresqlEnabled = config.homelab.services.postgresql.enable;
  caddyEnabled = config.homelab.services.caddy.enable;
in {
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Whether to enable Immich.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/mnt/tank/services/immich";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "photos.mantannest.com";
    };

    userId = lib.mkOption {
      default = 3001;
      type = lib.types.ints.u16;
      description = "User ID of Immich user";
    };

    groupId = lib.mkOption {
      default = 3001;
      type = lib.types.ints.u16;
      description = "Group ID of Immich group";
    };

    zfs = {
      enable = lib.mkEnableOption "Store Uptime Kuma dataDir on a ZFS dataset.";

      restic = {
        enable = lib.mkEnableOption "Enable restic backup";
      };

      dataset = lib.mkOption {
        type = lib.types.str;
        example = "dpool/tank/services/immich";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "ZFS properties for the dataset.";
      };
    };
  };

  config = lib.mkIf immichCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.uptime-kuma = lib.mkIf immichCfg.zfs.enable {
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

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${immichCfg.webDomain}" = {
            useACMEHost = immichCfg.webDomain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.immich.port}
            '';
          };
        };
      };
    };

    security = lib.mkIf caddyEnabled {
      acme.certs."${immichCfg.webDomain}".domain = "${immichCfg.webDomain}";
    };

    users.users = {
      immich.uid = immichCfg.userId;
    };

    users.groups = {
      immich.gid = immichCfg.groupId;
    };

    # Service hardening + mount ordering
    systemd = {
      services.immich-server = lib.mkMerge [
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

      services.immich-machine-learning = lib.mkMerge [
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

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${immichCfg.dataDir} 0750 immich immich -"
      ];
    };
  };
}
