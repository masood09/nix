{
  services.nginx.virtualHosts."chatgpt.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "chatgpt.mantannest.com";

    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      proxyWebsockets = true;
    };
  };
}
