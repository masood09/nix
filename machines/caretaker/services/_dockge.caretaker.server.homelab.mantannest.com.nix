{
  services.nginx.virtualHosts."dockge.caretaker.server.homelab.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "dockge.caretaker.server.homelab.mantannest.com";

    locations."/" = {
      proxyPass = "http://127.0.0.1:5001";
      proxyWebsockets = true;
    };
  };
}
