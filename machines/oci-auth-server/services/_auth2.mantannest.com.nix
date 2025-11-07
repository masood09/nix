{
  services.nginx.virtualHosts."auth2.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "mantannest.com";

    locations."/" = {
      proxyPass = "http://127.0.0.1:9091";
      proxyWebsockets = true;
    };
  };
}
