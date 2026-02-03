{
  config,
  lib,
  ...
}: {
  options.homelab.services.babybuddy = {
    enable = lib.mkEnableOption "Whether to enable Baby Buddy.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "babybuddy.${config.networking.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/babybuddy";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 8903;
      type = lib.types.port;
    };

    userId = lib.mkOption {
      default = 3004;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3004;
      type = lib.types.ints.u16;
    };

    zfs = {
      enable = lib.mkEnableOption "Store Baby Buddy dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/babybuddy";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };
}
