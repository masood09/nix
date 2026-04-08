# Options — Vaultwarden password manager (domain, port, ZFS).
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
        vaultwarden = {
          enable = lib.mkEnableOption "Whether to enable Vaultwarden.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "passwords.${config.networking.domain}";
            description = "Domain name for the Vaultwarden web interface.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/vaultwarden/";
            description = "Directory for Vaultwarden persistent data.";
          };

          listenAddress = lib.mkOption {
            default = "127.0.0.1";
            type = lib.types.str;
            description = "Address for Vaultwarden to bind to. Defaults to loopback so a local reverse proxy can publish the service without exposing Vaultwarden directly.";
          };

          listenPort = lib.mkOption {
            default = 8222;
            type = lib.types.port;
            description = "Port for the Vaultwarden web server.";
          };

          userId = lib.mkOption {
            default = 3003;
            type = lib.types.ints.u16;
            description = "UID for the Vaultwarden service user.";
          };

          groupId = lib.mkOption {
            default = 3003;
            type = lib.types.ints.u16;
            description = "GID for the Vaultwarden service group.";
          };

          openFirewall = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Whether to open the listen port in the firewall. Keep this disabled when Vaultwarden is only meant to be reachable through a local reverse proxy.";
          };

          oauth = {
            providerHost = lib.mkOption {
              type = lib.types.str;
              default = "auth.${config.networking.domain}";
              description = "Hostname of the OAuth/OIDC provider.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "vaultwarden";
              description = "OAuth client ID for Vaultwarden.";
            };
          };

          zfs = zfsOpts {
            serviceName = "Vaultwarden";
            dataset = "dpool/tank/services/vaultwarden";
            properties = {
              logbias = "latency";
              recordsize = "16K";
              redundant_metadata = "most";
            };
          };
        };
      };
    };
  };
}
