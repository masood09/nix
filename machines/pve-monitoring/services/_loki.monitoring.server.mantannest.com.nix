{config, ...}: {
  sops.secrets = {
    "nginx-loki-auth" = {
      owner = "nginx";
      sopsFile = ./../../../secrets/pve-monitoring.yaml;
    };
  };

  services.nginx.virtualHosts."loki.monitoring.server.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "loki.monitoring.server.mantannest.com";

    locations."/" = {
      basicAuthFile = config.sops.secrets."nginx-loki-auth".path;
      proxyPass = "http://127.0.0.1:3100";
      extraConfig = ''
        proxy_redirect off;
      '';
    };

    locations."/ready" = {
      proxyPass = "http://127.0.0.1:3100";
      extraConfig = ''
        proxy_redirect off;
        auth_basic "off";
      '';
    };
  };
}
