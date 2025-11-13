{
  services.nginx.virtualHosts."homeassistant.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "homeassistant.mantannest.com";

    locations."/" = {
      proxyPass = "http://127.0.0.1:8123";
      proxyWebsockets = true;
    };
  };
}
