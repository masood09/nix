{
  config,
  lib,
  ...
}: {
  options.homelab.services.mailarchiver = {
    enable = lib.mkEnableOption "Whether to enable Mail Archiver.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "mailarchiver.${config.networking.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/mailarchiver";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 8913;
      type = lib.types.port;
    };

    oauth = {
      enable = lib.mkOption {
        type = lib.types.str;
        default = "true";
      };

      providerHost = lib.mkOption {
        type = lib.types.str;
        default = "auth.${config.networking.domain}";
      };

      issuerURL = lib.mkOption {
        type = lib.types.str;
        default = "https://${config.homelab.services.mailarchiver.oauth.providerHost}/application/o/mailarchiver";
      };

      clientID = lib.mkOption {
        type = lib.types.str;
        default = "mailarchiver";
      };

      disablePasswordLogin = lib.mkOption {
        type = lib.types.str;
        default = "true";
      };

      autoRedirect = lib.mkOption {
        type = lib.types.str;
        default = "true";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store MailArchiver dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/mailarchiver";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          recordsize = "16K";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };
}
