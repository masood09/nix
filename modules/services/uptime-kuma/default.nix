{
  config,
  lib,
  ...
}: let
  uptimeKumaCfg = config.homelab.services.uptime-kuma;
  caddyEnabled = config.homelab.services.caddy.enable;
in {
  options.homelab.services.uptime-kuma = {
    enable = lib.mkEnableOption "Whether to enable Uptime Kuma.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/uptime-kuma/";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "uptime.mantannest.com";
    };

    userId = lib.mkOption {
      default = 3002;
      type = lib.types.ints.u16;
      description = "User ID of Alloy user";
    };

    groupId = lib.mkOption {
      default = 3002;
      type = lib.types.ints.u16;
      description = "Group ID of Alloy group";
    };

    zfs = {
      enable = lib.mkEnableOption "Store Uptime Kuma dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        example = "rpool/root/var/lib/uptime-kuma";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "ZFS properties for the dataset.";
      };
    };
  };

  config = {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.uptime-kuma = lib.mkIf (uptimeKumaCfg.enable && uptimeKumaCfg.zfs.enable) {
      inherit (uptimeKumaCfg.zfs) dataset properties;

      enable = true;
      mountpoint = uptimeKumaCfg.dataDir;
      requiredBy = ["uptime-kuma.service"];
    };

    services = lib.mkIf uptimeKumaCfg.enable {
      uptime-kuma = {
        inherit (uptimeKumaCfg) enable;

        settings = {
          DATA_DIR = uptimeKumaCfg.dataDir;
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${uptimeKumaCfg.webDomain}" = {
            useACMEHost = uptimeKumaCfg.webDomain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.uptime-kuma.settings.PORT}
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && uptimeKumaCfg.enable) {
      acme.certs."${uptimeKumaCfg.webDomain}".domain = "${uptimeKumaCfg.webDomain}";
    };

    users = {
      users = lib.optionalAttrs uptimeKumaCfg.enable {
        uptime-kuma = {
          isSystemUser = true;
          group = "uptime-kuma";
          uid = uptimeKumaCfg.userId;
        };
      };

      groups = lib.optionalAttrs uptimeKumaCfg.enable {
        uptime-kuma = {
          gid = uptimeKumaCfg.groupId;
        };
      };
    };

    # Service hardening + mount ordering
    systemd.services.uptime-kuma = lib.mkMerge [
      {
        # Unit-level ordering / mount requirements
        unitConfig = {
          RequiresMountsFor = [uptimeKumaCfg.dataDir];
        };

        serviceConfig = {
          DynamicUser = lib.mkForce false;

          # stop systemd from trying to manage /var/lib/private + bind-mount behavior
          StateDirectory = lib.mkForce null;
          StateDirectoryMode = lib.mkForce null;

          User = "uptime-kuma";
          Group = "uptime-kuma";

          # with ProtectSystem=strict, you must explicitly allow writes here
          ReadWritePaths = [uptimeKumaCfg.dataDir];
        };
      }

      (lib.mkIf (uptimeKumaCfg.enable && uptimeKumaCfg.zfs.enable) {
        requires = ["zfs-dataset-uptime-kuma.service"];
        after = ["zfs-dataset-uptime-kuma.service"];
      })
    ];

    systemd.tmpfiles.rules = lib.mkIf uptimeKumaCfg.enable [
      # Ensure base dir exists and is owned correctly
      "d ${uptimeKumaCfg.dataDir} 0750 uptime-kuma uptime-kuma -"

      # Pre-create subdirs Kuma expects
      "d ${uptimeKumaCfg.dataDir}/upload 0750 uptime-kuma uptime-kuma -"
      "d ${uptimeKumaCfg.dataDir}/data 0750 uptime-kuma uptime-kuma -"
    ];
  };
}
