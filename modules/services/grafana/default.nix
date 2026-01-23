{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  grafanaCfg = homelabCfg.services.grafana;
  caddyEnabled = config.services.caddy.enable;
  lokiCfg = homelabCfg.services.loki;
  prometheusEnabled = config.services.prometheus.enable;

  grafanaDataDir = lib.removeSuffix "/" (toString grafanaCfg.dataDir);
in {
  options.homelab.services.grafana = {
    enable = lib.mkEnableOption "Whether to enable Grafana.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "grafana.mantannest.com";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/grafana/";
    };

    oauth = {
      providerHost = lib.mkOption {
        type = lib.types.str;
        default = "auth.mantannest.com";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "0i7eoX2Og14H7lL4v3Mh8C2WhSoN2dLCiq7yJgb4";
      };

      scopes = lib.mkOption {
        type = lib.types.str;
        default = "openid email profile";
      };

      roleAttributePath = lib.mkOption {
        type = lib.types.str;
        default = "contains(groups, 'Homelab Admins') && 'Admin' || 'Viewer'";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Grafana dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/grafana";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "all";
        };
      };
    };
  };

  config = lib.mkIf grafanaCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.grafana = lib.mkIf grafanaCfg.zfs.enable {
      inherit (grafanaCfg.zfs) dataset properties;

      enable = true;
      mountpoint = grafanaDataDir;

      requiredBy = [
        "grafana.service"
      ];

      restic = {
        enable = false;
      };
    };

    services = {
      grafana = {
        enable = true;

        provision = {
          enable = true;

          datasources.settings.datasources =
            lib.optionals lokiCfg.enable [
              {
                name = "Loki";
                type = "loki";
                access = "proxy";
                url = "http://127.0.0.1:${toString lokiCfg.listenPort}";
              }
            ]
            ++ lib.optionals prometheusEnabled [
              {
                name = "Prometheus";
                type = "prometheus";
                access = "proxy";
                url = "http://127.0.0.1:${toString config.services.prometheus.port}";
              }
            ];

          dashboards.settings.providers = let
            makeReadOnly = x:
              lib.pipe x [
                builtins.readFile
                builtins.fromJSON
                (x: x // {editable = false;})
                builtins.toJSON
                (pkgs.writeText (builtins.baseNameOf x))
              ];
          in [
            {
              name = "Authentik";
              type = "file";
              url = "https://grafana.com/api/dashboards/14837/revisions/2/download";
              options.path = makeReadOnly ./dashboards/authentik.json;
            }
            {
              name = "Blocky";
              type = "file";
              url = "https://grafana.com/api/dashboards/13768/revisions/6/download";
              options.path = makeReadOnly ./dashboards/blocky.json;
            }
            {
              name = "Node Exporter Full";
              type = "file";
              url = "https://grafana.com/api/dashboards/1860/revisions/42/download";
              options.path = makeReadOnly ./dashboards/node-exporter-full.json;
            }
            {
              name = "PostgreSQL";
              type = "file";
              url = "https://grafana.com/api/dashboards/9628/revisions/8/download";
              options.path = makeReadOnly ./dashboards/postgresql.json;
            }
          ];
        };

        settings = {
          auth.signout_redirect_url = "https://${grafanaCfg.oauth.providerHost}/application/o/grafana/end-session/";
          auth.oauth_auto_login = true;

          "auth.generic_oauth".name = "authentik";
          "auth.generic_oauth".enabled = true;
          "auth.generic_oauth".client_id = "0i7eoX2Og14H7lL4v3Mh8C2WhSoN2dLCiq7yJgb4";
          "auth.generic_oauth".client_secret = "$__file{${
            config.sops.secrets."grafana-authentik-client-secret".path
          }}";
          "auth.generic_oauth".scopes = "openid email profile";
          "auth.generic_oauth".auth_url = "https://${grafanaCfg.oauth.providerHost}/application/o/authorize/";
          "auth.generic_oauth".token_url = "https://${grafanaCfg.oauth.providerHost}/application/o/token/";
          "auth.generic_oauth".api_url = "https://${grafanaCfg.oauth.providerHost}/application/o/userinfo/";
          "auth.generic_oauth".role_attribute_path = "contains(groups, 'Homelab Admins') && 'Admin' || 'Viewer'";

          analytics.reporting_enabled = false;

          server = {
            enforce_domain = true;
            enable_gzip = true;
            domain = grafanaCfg.webDomain;
            root_url = "https://${grafanaCfg.webDomain}/";
          };
        };
      };

      # Caddy reverse proxy with auth except /ready
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${grafanaCfg.webDomain}" = {
            useACMEHost = grafanaCfg.webDomain;

            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}
            '';
          };
        };
      };
    };

    security = lib.mkIf caddyEnabled {
      acme.certs."${grafanaCfg.webDomain}".domain = "${grafanaCfg.webDomain}";
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        grafana = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [grafanaDataDir];
            };

            requires = ["grafana-permissions.service"];
            after = ["grafana-permissions.service"];
          }

          (lib.mkIf grafanaCfg.zfs.enable {
            requires = ["zfs-dataset-grafana.service"];
            after = ["zfs-dataset-grafana.service"];
          })
        ];

        grafana-permissions = {
          description = "Fix Grafana dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["grafana.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals grafanaCfg.zfs.enable ["zfs-dataset-grafana.service"];
          requires =
            lib.optionals grafanaCfg.zfs.enable ["zfs-dataset-grafana.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/install -d -m 0700 -o grafana -g grafana ${grafanaDataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${grafanaDataDir} 0700 grafana grafana -"
        "z ${grafanaDataDir} 0700 grafana grafana -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !grafanaCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          grafanaDataDir
        ];
      };
  };
}
