# Options — Headscale mesh VPN (domain, ports, OIDC, Headplane UI, ZFS).
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
        headscale = {
          enable = lib.mkEnableOption "Whether to enable Headscale.";

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/headscale/";
            description = "Directory for Headscale data storage.";
          };

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "headscale.${config.networking.domain}";
            description = "Domain name for the Headscale web interface.";
          };

          metricsPort = lib.mkOption {
            default = 9091;
            type = lib.types.port;
            description = "Port for the Headscale metrics endpoint.";
          };

          oidc = {
            enable = lib.mkEnableOption "Whether to enable OIDC.";

            issuer = lib.mkOption {
              type = lib.types.str;
              default = "https://auth.${config.networking.domain}/application/o/headscale/";
              description = "OIDC issuer URL for Headscale authentication.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "headscale";
              description = "OIDC client ID for Headscale authentication.";
            };
          };

          headplane = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Whether to enable the Headplane admin UI for Headscale.";
            };

            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/headplane/";
              description = "Directory for Headplane data storage.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 8909;
              description = "Port for the Headplane admin UI.";
            };

            zfs = zfsOpts {
              serviceName = "Headplane";
              dataset = "rpool/root/var/lib/headplane";
              properties = {
                logbias = "latency";
                recordsize = "16K";
                redundant_metadata = "most";
              };
              withRestic = true;
            };
          };

          zfs = zfsOpts {
            serviceName = "Headscale";
            dataset = "rpool/root/var/lib/headscale";
            properties = {
              logbias = "latency";
              recordsize = "16K";
              redundant_metadata = "most";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
