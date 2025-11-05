{ config, ... }: {
  sops.secrets = {
    "nginx-loki-auth" = {
      owner = "nginx";
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
  };

  services.nginx.virtualHosts."loki.monitoring.server.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "monitoring.server.mantannest.com";
    locations."/" = {
      basicAuthFile = config.sops.secrets."nginx-loki-auth".path;
      proxyPass = "http://localhost:3100";
      extraConfig = ''
        proxy_read_timeout 1800s;
        proxy_connect_timeout 1600s;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Keep-Alive";
        proxy_set_header Proxy-Connection "Keep-Alive";
        proxy_redirect off;
      '';
    };

    locations."/ready" = {
      proxyPass = "http://localhost:3100";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Connection "Keep-Alive";
        proxy_set_header Proxy-Connection "Keep-Alive";
        proxy_redirect off;
        auth_basic "off";
      '';
    };
  };
}
