{
  services.nginx.virtualHosts."headscale.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "headscale.mantannest.com";

    locations."/" = {
      proxyPass = "http://app-server-1.internal.oci.mantannest.com:8080";
      proxyWebsockets = true;

      extraConfig = ''
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection $connection_upgrade;
        proxy_buffering off;
        add_header Strict-Transport-Security "max-age=15552000; includeSubDomains" always;
      '';
    };
  };
}
