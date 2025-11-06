{config, ...}: {
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
      proxyPass = "http://127.0.0.1:3100";
      extraConfig = ''
        proxy_read_timeout 1800s;
        proxy_connect_timeout 1600s;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
      '';
    };

    locations."/ready" = {
      proxyPass = "http://127.0.0.1:3100";
      extraConfig = ''
        proxy_read_timeout 1800s;
        proxy_connect_timeout 1600s;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        auth_basic "off";
      '';
    };
  };
}
