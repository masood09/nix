# Grafana — observability dashboards with Loki + Prometheus datasources.
# Authenticates via Authentik OIDC. Provisions Node Exporter and PostgreSQL
# dashboards as read-only on activation.
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

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "grafana";
    dataDir = grafanaDataDir;
    user = "grafana";
    group = "grafana";
    mainServices = ["grafana"];
    zfs = {
      inherit (grafanaCfg.zfs) enable;
      datasetServiceName = "zfs-dataset-grafana";
    };
  };
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf grafanaCfg.enable {
    # ZFS dataset for dataDir
    homelab = {
      zfs = {
        datasets = {
          grafana = lib.mkIf grafanaCfg.zfs.enable {
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
        };
      };
    };

    services = {
      grafana = {
        enable = true;

        provision = {
          enable = true;

          datasources = {
            settings = {
              datasources =
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
            };
          };

          dashboards = {
            settings = {
              providers = let
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
                  name = "Node Exporter Full";
                  type = "file";
                  url = "https://grafana.com/api/dashboards/1860/revisions/42/download";
                  options = {
                    path = makeReadOnly ./dashboards/node-exporter-full.json;
                  };
                }
                {
                  name = "PostgreSQL";
                  type = "file";
                  url = "https://grafana.com/api/dashboards/9628/revisions/8/download";
                  options = {
                    path = makeReadOnly ./dashboards/postgresql.json;
                  };
                }
              ];
            };
          };
        };

        settings = {
          # nixos-26.05 removed Grafana's built-in default secret_key (used to
          # sign auth cookies / encrypt DB-stored secrets) and now asserts it be
          # set explicitly. Sourced from sops per machine via the $__file
          # provider; declare the `grafana/secret-key` secret in each Grafana
          # machine's _secrets.nix.
          security = {
            secret_key = "$__file{${
              config.sops.secrets."grafana/secret-key".path
            }}";

            # Local break-glass admin so Grafana stays reachable when Authentik
            # is down (the very thing you may be using Grafana to debug).
            # Password from sops — declare grafana/admin-password in each Grafana
            # host's _secrets.nix. NOTE: Grafana only applies admin_password when
            # it first creates the admin user; on an already-initialised install
            # seed it once with `grafana-cli admin reset-admin-password`.
            admin_user = "admin";
            admin_password = "$__file{${
              config.sops.secrets."grafana/admin-password".path
            }}";
          };

          auth = {
            signout_redirect_url = "https://${grafanaCfg.oauth.providerHost}/application/o/grafana/end-session/";

            # Do not auto-redirect to Authentik: render the login page with the
            # local username/password form AND the "Sign in with authentik"
            # button, so the local admin is always a usable fallback. Keep the
            # login form explicitly enabled against future regressions.
            oauth_auto_login = false;
            disable_login_form = false;
          };

          "auth.generic_oauth" = {
            name = "authentik";
            enabled = true;
            client_id = grafanaCfg.oauth.clientId;
            client_secret = "$__file{${
              config.sops.secrets."grafana/authentik-client-secret".path
            }}";
            inherit (grafanaCfg.oauth) scopes;
            auth_url = "https://${grafanaCfg.oauth.providerHost}/application/o/authorize/";
            token_url = "https://${grafanaCfg.oauth.providerHost}/application/o/token/";
            api_url = "https://${grafanaCfg.oauth.providerHost}/application/o/userinfo/";
            role_attribute_path = grafanaCfg.oauth.roleAttributePath;
          };

          analytics = {
            reporting_enabled = false;
          };

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
            useACMEHost = config.networking.domain;

            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.grafana.settings.server.http_port}
            '';
          };
        };
      };
    };

    inherit (permSvc) systemd;

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = grafanaCfg.zfs.enable;
      directories = [grafanaDataDir];
    };
  };
}
