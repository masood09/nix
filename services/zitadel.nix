{config, ...}: let
  domain = "mantannest.com";
in {
  sops.secrets = {
    "zitadel-master-key" = {
      owner = "zitadel";
      mode = "0400";
    };
    "zitadel-admin-steps" = {
      owner = "zitadel";
      mode = "0400";
    };
    "zitadel-settings" = {
      owner = "zitadel";
      mode = "0400";
    };
  };

  services = {
    zitadel = {
      enable = true;
      openFirewall = true;

      masterKeyFile = "${config.sops.secrets."zitadel-master-key".path}";
      extraStepsPaths = ["${config.sops.secrets."zitadel-admin-steps".path}"];
      extraSettingsPaths = ["${config.sops.secrets."zitadel-settings".path}"];

      tlsMode = "external";
      settings = {
        Port = 39995;
        ExternalPort = 443;
        ExternalDomain = "auth.${domain}";
        Database = {
          postgres = {
            Host = "oci-db-server.publicsubnet.ocivcn.oraclevcn.com";
            Port = 5432;
            Database = "zitadel";
            MaxOpenConns = 15;
            MaxIdleConns = 10;
            MaxConnLifetime = "1h";
            MaxConnIdleTime = "5m";
            User = {
              Username = "zitadel";
              SSL = {
                Mode = "verify-full";
                RootCert = "/etc/ssl/certs/ca-certificates.crt";
              };
            };
            Admin = {
              Username = "postgres";
              SSL = {
                Mode = "verify-full";
                RootCert = "/etc/ssl/certs/ca-certificates.crt";
              };
            };
          };
        };
      };
    };

    # Proxy the SSO provider
    nginx = {
      enable = true;
      virtualHosts."auth.${domain}" = {
        forceSSL = true;
        enableACME = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:39995";
          proxyWebsockets = true;
          extraConfig = ''
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
          '';
        };
      };
    };
  };
}
