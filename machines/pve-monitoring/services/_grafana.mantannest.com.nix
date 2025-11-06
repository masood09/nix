{config, ...}: {
  services.nginx.virtualHosts."grafana.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "monitoring.server.mantannest.com";

    locations."/" = {
      proxyPass = "http://localhost:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
      recommendedProxySettings = true;
    };
  };
}
