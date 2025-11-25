{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  sops.secrets = {
    "grafana-authentik-client-secret" = {
      owner = "grafana";
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
  };

  services = {
    grafana = {
      enable = true;
      openFirewall = true;

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
          }
          {
            name = "Prometheus";
            type = "prometheus";
            access = "proxy";
            url = "http://127.0.0.1:9090";
          }
        ];

        dashboards.settings.providers = [
          {
            name = "My Dashboards";
            disableDeletion = true;

            options = {
              path = "/etc/grafana-dashboards";
              foldersFromFilesStructure = true;
            };
          }
        ];
      };

      settings = {
        auth.signout_redirect_url = "https://auth.mantannest.com/application/o/grafana/end-session/";
        auth.oauth_auto_login = true;

        "auth.generic_oauth".name = "authentik";
        "auth.generic_oauth".enabled = true;
        "auth.generic_oauth".client_id = "0i7eoX2Og14H7lL4v3Mh8C2WhSoN2dLCiq7yJgb4";
        "auth.generic_oauth".client_secret = "$__file{${
          config.sops.secrets."grafana-authentik-client-secret".path
        }}";
        "auth.generic_oauth".scopes = "openid email profile";
        "auth.generic_oauth".auth_url = "https://auth.mantannest.com/application/o/authorize/";
        "auth.generic_oauth".token_url = "https://auth.mantannest.com/application/o/token/";
        "auth.generic_oauth".api_url = "https://auth.mantannest.com/application/o/userinfo/";
        "auth.generic_oauth".role_attribute_path = "contains(groups, 'Homelab Admins') && 'Admin' || 'Viewer'";

        analytics.reporting_enabled = false;

        server = {
          enforce_domain = true;
          enable_gzip = true;
          domain = "grafana.mantannest.com";
          root_url = "https://grafana.mantannest.com/";
        };
      };
    };
  };

  environment.persistence."/nix/persist" = lib.mkIf (!homelabCfg.isRootZFS) {
    directories = [
      "/var/lib/grafana"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/grafana 0700 grafana grafana -"
  ];

  environment.etc."grafana-dashboards/node-exporter-full.json".source =
    ./../../../files/grafana/dashboards/node-exporter-full.json;
  environment.etc."grafana-dashboards/blocky-grafana.json".source =
    ./../../../files/grafana/dashboards/blocky-grafana.json;
}
