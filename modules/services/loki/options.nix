{
  config,
  lib,
  ...
}: {
  options.homelab.services.loki = {
    enable = lib.mkEnableOption "Whether to enable Loki.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "loki.${config.networking.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/loki/";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 3100;
      type = lib.types.port;
    };

    userId = lib.mkOption {
      default = 3005;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3005;
      type = lib.types.ints.u16;
    };

    retentionPeriod = {
      default = lib.mkOption {
        type = lib.types.str;
        default = "240h"; # 10d
      };

      debug = lib.mkOption {
        type = lib.types.str;
        default = "24h"; # 1d
      };

      info = lib.mkOption {
        type = lib.types.str;
        inherit (config.homelab.services.loki.retentionPeriod) default;
      };

      warn = lib.mkOption {
        type = lib.types.str;
        default = "720h"; # 30d
      };

      error = lib.mkOption {
        type = lib.types.str;
        default = "1440h"; # 60d
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Loki dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/loki";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "metadata";
        };
      };
    };
  };
}
