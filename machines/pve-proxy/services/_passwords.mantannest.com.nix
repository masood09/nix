{
  services.nginx.virtualHosts."passwords.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "passwords.mantannest.com";

    locations."/" = {
      proxyPass = "http://pve-app-1.server.homelab.mantannest.com:8222";
      proxyWebsockets = true;
      extraConfig = ''
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
      '';
    };
  };
}
