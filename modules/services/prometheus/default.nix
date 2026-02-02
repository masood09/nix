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
in {
  options.homelab.services.prometheus = {
    enable = lib.mkEnableOption "Whether to enable Prometheus.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "prometheus.${config.networking.domain}";
    };

    zfs = {
      enable = lib.mkEnableOption "Store Prometheus dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/prometheus";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "throughput";
          recordsize = "16K";
          redundant_metadata = "most";
          relatime = "off";
          primarycache = "all";
        };
      };
    };
  };

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
        enable = true;
        listenAddress = "127.0.0.1";
        retentionTime = "30d";
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

    # Service hardening + mount ordering
    systemd = {
      services = {
        prometheus = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [prometheusDataDir];
            };

            requires = ["prometheus-permissions.service"];
            after = ["prometheus-permissions.service"];
          }

          (lib.mkIf cfg.zfs.enable {
            requires = ["zfs-dataset-prometheus.service"];
            after = ["zfs-dataset-prometheus.service"];
          })
        ];

        prometheus-permissions = {
          description = "Fix Prometheus dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["prometheus.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals cfg.zfs.enable ["zfs-dataset-prometheus.service"];
          requires =
            lib.optionals cfg.zfs.enable ["zfs-dataset-prometheus.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/install -d -m 0700 -o prometheus -g prometheus ${prometheusDataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${prometheusDataDir} 0700 prometheus prometheus -"
        "z ${prometheusDataDir} 0700 prometheus prometheus -"
      ];
    };

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
