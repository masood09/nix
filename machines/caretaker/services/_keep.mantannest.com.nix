{
  services.nginx.virtualHosts."keep.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "keep.mantannest.com";

    locations."/" = {
      proxyPass = "http://127.0.0.1:8081";
      proxyWebsockets = true;
    };
  };
}
