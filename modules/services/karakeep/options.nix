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
      description = "Domain name for the Karakeep web interface.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/karakeep/";
      description = "Directory for Karakeep persistent data.";
    };

    listenPort = lib.mkOption {
      default = 8904;
      type = lib.types.port;
      description = "Port for the Karakeep web server.";
    };

    userId = lib.mkOption {
      default = 3007;
      type = lib.types.ints.u16;
      description = "UID for the Karakeep service user.";
    };

    groupId = lib.mkOption {
      default = 3007;
      type = lib.types.ints.u16;
      description = "GID for the Karakeep service group.";
    };

    openFirewall = lib.mkOption {
      default = false;
      type = lib.types.bool;
      description = "Whether to open the listen port in the firewall.";
    };

    oauth = {
      providerHost = lib.mkOption {
        type = lib.types.str;
        default = "auth.${config.networking.domain}";
        description = "Hostname of the OAuth/OIDC provider.";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "karakeep";
        description = "OAuth client ID for Karakeep.";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Karakeep dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/karakeep";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "all";
        };
        description = "ZFS properties to apply to the dataset.";
      };
    };
  };
}
