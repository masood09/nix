{config, ...}: {
  imports = [
    ./_acme.nix
    ./_nginx.nix
  ];

  services = {
    grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "127.0.0.1";
          http_port = 3000;
          enforce_domain = true;
          enable_gzip = true;
          domain = "grafana.mantannest.com";
        };

        analytics.reporting_enabled = false;
      };
    };

    nginx.virtualHosts."grafana.mantannest.com" = {
      forceSSL = true;
      useACMEHost = "mantannest.com";

      locations."/" = {
        proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
      };
    };
  };
}
