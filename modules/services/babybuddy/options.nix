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
      description = "Domain name for the Baby Buddy web interface.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/babybuddy";
      description = "Directory for Baby Buddy data storage.";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
      description = "Address Baby Buddy listens on for HTTP requests.";
    };

    listenPort = lib.mkOption {
      default = 8903;
      type = lib.types.port;
      description = "Port Baby Buddy listens on for HTTP requests.";
    };

    userId = lib.mkOption {
      default = 3004;
      type = lib.types.ints.u16;
      description = "UID for the Baby Buddy service user.";
    };

    groupId = lib.mkOption {
      default = 3004;
      type = lib.types.ints.u16;
      description = "GID for the Baby Buddy service group.";
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
