{
  config,
  lib,
  ...
}: {
  options.homelab.services.karakeep = {
    enable = lib.mkEnableOption "Whether to enable Karakeep.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "keep.${config.networking.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/karakeep/";
    };

    listenPort = lib.mkOption {
      default = 8904;
      type = lib.types.port;
    };

    userId = lib.mkOption {
      default = 3007;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3007;
      type = lib.types.ints.u16;
    };

    oauth = {
      providerHost = lib.mkOption {
        type = lib.types.str;
        default = "auth.${config.networking.domain}";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "karakeep";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Karakeep dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/karakeep";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "all";
        };
      };
    };
  };
}
