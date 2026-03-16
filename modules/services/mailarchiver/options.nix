{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options.homelab.services = {
    mailarchiver = {
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

      port = lib.mkOption {
        default = 8913;
        type = lib.types.port;
      };

      userId = lib.mkOption {
        default = 3011;
        type = lib.types.ints.u16;
      };

      groupId = lib.mkOption {
        default = 3011;
        type = lib.types.ints.u16;
      };

      oauth = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
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
          type = lib.types.bool;
          default = true;
        };

        autoRedirect = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };

      zfs = zfsOpts {
        serviceName = "MailArchiver";
        dataset = "fpool/fast/services/mailarchiver";
        properties = {
          recordsize = "16K";
        };
      };
    };
  };
}
