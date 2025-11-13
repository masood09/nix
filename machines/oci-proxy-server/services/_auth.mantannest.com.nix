{
  services.nginx.virtualHosts."auth.mantannest.com" = {
    forceSSL = true;
    useACMEHost = "auth.mantannest.com";

    locations."/" = {
      proxyPass = "https://app-server-1.internal.oci.mantannest.com:9443";
      proxyWebsockets = true;
    };
  };
}
