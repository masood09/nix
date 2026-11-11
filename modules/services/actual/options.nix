# Options — Actual Budget personal finance server (domain, port, OIDC, ZFS).
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
        actual = {
          enable = lib.mkEnableOption "Actual Budget personal finance server.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "budget.${config.networking.domain}";
            description = "Public hostname for Actual Budget.";
          };

          dataDir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/actual";
            description = "Directory holding Actual's server-files (account.sqlite) and user-files (budget blobs). Upstream warns that changing this after first start can break the instance.";
          };

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address on which Actual listens behind Caddy.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8919;
            description = "Port on which Actual listens.";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3019;
            description = "UID for the Actual service user.";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3019;
            description = "GID for the Actual service group.";
          };

          oidc = {
            enable = lib.mkEnableOption ''
              OpenID-only login for Actual via Authentik (password login is
              disallowed). Requires an `actual/oidc-client-secret` key in the
              host's secrets.sops.yaml and a matching entry in its _secrets.nix
              with `sopsFile = ./secrets.sops.yaml`; this module sets
              `owner = "actual"` and `restartUnits` on it'';

            discoveryUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://auth.${config.networking.domain}/application/o/actual/";
              description = "OpenID provider discovery URL.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "actual";
              description = "OpenID client ID for Actual.";
            };
          };

          zfs = zfsOpts {
            serviceName = "Actual Budget";
            dataset = "dpool/tank/services/actual";
            properties = {
              logbias = "latency";
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
