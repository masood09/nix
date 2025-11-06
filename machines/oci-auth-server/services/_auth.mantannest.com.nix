{
  services.nginx.virtualHosts."auth.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "mantannest.com";

    locations."/" = {
      proxyPass = "https://127.0.0.1:9443";
      proxyWebsockets = true;
    };
  };
}
