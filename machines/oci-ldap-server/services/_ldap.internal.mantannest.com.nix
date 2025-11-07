{config, ...}: {
  services.nginx = {
    defaultHTTPListenPort = 8080;
    defaultSSLListenPort = 8443;

    virtualHosts."ldap.internal.mantannest.com" = {
      forceSSL = true;
      useACMEHost = "mantannest.com";

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.lldap.settings.http_port}";
      };
    };
  };

  security.acme.certs."mantannest.com" = {
    extraDomainNames = [
      "ldap.internal.mantannest.com"
    ];
  };
}
