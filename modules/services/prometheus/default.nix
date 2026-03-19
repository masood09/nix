# Prometheus — time-series metrics store. Receives remote-write from Alloy
# agents across the fleet. Protected by basic auth via Caddy.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.prometheus;
  caddyEnabled = config.services.caddy.enable;

  prometheusDataDir = "/var/lib/${config.services.prometheus.stateDir}";

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "prometheus";
    dataDir = prometheusDataDir;
    user = "prometheus";
    group = "prometheus";
    mainServices = ["prometheus"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-prometheus";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.prometheus = lib.mkIf cfg.zfs.enable {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = prometheusDataDir;

      requiredBy = [
        "prometheus.service"
      ];

      restic = {
        enable = false;
      };
    };

    services = {
      prometheus = {
        inherit (cfg) retentionTime;

        enable = true;
        listenAddress = "127.0.0.1";
        webExternalUrl = "https://${cfg.webDomain}";

        extraFlags = [
          "--web.enable-remote-write-receiver"
        ];
      };

      # Caddy reverse proxy with auth except /ready
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;

            extraConfig = ''
              route {
                # No auth for readiness
                handle /-/healthy {
                  reverse_proxy http://127.0.0.1:${toString config.services.prometheus.port}
                }

                handle /-/ready {
                  reverse_proxy http://127.0.0.1:${toString config.services.prometheus.port}
                }

                # Everything else requires basic auth
                handle {
                  basic_auth {
                    {$PROMETHEUS_USERNAME} {$PROMETHEUS_BCRYPT}
                  }
                  reverse_proxy http://127.0.0.1:${toString config.services.prometheus.port}
                }
              }
            '';
          };
        };
      };
    };

    inherit (permSvc) systemd;

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !cfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          prometheusDataDir
        ];
      };
  };
}
