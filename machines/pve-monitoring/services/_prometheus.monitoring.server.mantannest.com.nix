{config, ...}: {
  sops.secrets = {
    "nginx-prometheus-auth" = {
      owner = "nginx";
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
  };

  services.nginx.virtualHosts."prometheus.monitoring.server.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "monitoring.server.mantannest.com";
    locations."/" = {
      basicAuthFile = config.sops.secrets."nginx-prometheus-auth".path;
      proxyPass = "http://127.0.0.1:9090";
      extraConfig = ''
        proxy_redirect off;
      '';
    };

    locations."/-/healthy" = {
      proxyPass = "http://127.0.0.1:9090";
      extraConfig = ''
        proxy_redirect off;
        auth_basic "off";
      '';
    };

    locations."/-/ready" = {
      proxyPass = "http://127.0.0.1:9090";
      extraConfig = ''
        proxy_redirect off;
        auth_basic "off";
      '';
    };
  };
}
