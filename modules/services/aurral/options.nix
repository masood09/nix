# Options — Aurral music discovery and playlist manager.
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        aurral = {
          enable = lib.mkEnableOption "Aurral music discovery and playlist manager.";

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/aurral";
            description = "Directory for Aurral's database, settings, users, and jobs.";
          };

          mediaDir = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/tank/media/library";
            description = "Shared media root that Aurral reads and writes.";
          };

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address on which Aurral listens behind Caddy.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8915;
            description = "Port on which Aurral listens.";
          };

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "aurral.${config.networking.domain}";
            description = "Public hostname for Aurral.";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3015;
            description = "UID for the Aurral service user.";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3015;
            description = "GID for the Aurral service group.";
          };

          oidc = {
            enable = lib.mkEnableOption "Native OIDC authentication for Aurral.";

            issuer = lib.mkOption {
              type = lib.types.str;
              default = "https://auth.${config.networking.domain}/application/o/aurral/";
              description = "OIDC issuer URL for Aurral.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "aurral";
              description = "OIDC client ID for Aurral.";
            };

            adminUsers = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "OIDC usernames that receive the Aurral administrator role.";
            };
          };

          zfs = zfsOpts {
            serviceName = "Aurral";
            dataset = "dpool/tank/services/aurral";
            properties = {
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
