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
        description = "Domain name for the Mail Archiver web interface.";
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/mailarchiver";
        description = "Directory for Mail Archiver data storage.";
      };

      listenAddress = lib.mkOption {
        default = "127.0.0.1";
        type = lib.types.str;
        description = "Address Mail Archiver listens on for HTTP requests.";
      };

      port = lib.mkOption {
        default = 8913;
        type = lib.types.port;
        description = "Port Mail Archiver listens on for HTTP requests.";
      };

      userId = lib.mkOption {
        default = 3011;
        type = lib.types.ints.u16;
        description = "UID for the Mail Archiver service user.";
      };

      groupId = lib.mkOption {
        default = 3011;
        type = lib.types.ints.u16;
        description = "GID for the Mail Archiver service group.";
      };

      oauth = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to enable OAuth authentication.";
        };

        providerHost = lib.mkOption {
          type = lib.types.str;
          default = "auth.${config.networking.domain}";
          description = "Hostname of the OAuth/OIDC provider.";
        };

        issuerURL = lib.mkOption {
          type = lib.types.str;
          default = "https://${config.homelab.services.mailarchiver.oauth.providerHost}/application/o/mailarchiver";
          description = "OIDC issuer URL for Mail Archiver authentication.";
        };

        clientID = lib.mkOption {
          type = lib.types.str;
          default = "mailarchiver";
          description = "OAuth client ID for Mail Archiver.";
        };

        disablePasswordLogin = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to disable password-based login when OAuth is enabled.";
        };

        autoRedirect = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to automatically redirect to the OAuth provider for login.";
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
