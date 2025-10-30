{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
  };

  domain = "mantannest.com";
  netbirdDomain = "netbird.${domain}";
  oidcDomain = "auth.${domain}";
  oidcIssuer = "https://${oidcDomain}/application/o/netbird/";
  oidcEndpoint = "https://${oidcDomain}/application/o/netbird/.well-known/openid-configuration";
  oidcKeysLocation = "https://${oidcDomain}/application/o/netbird/jwks/";
  oidcTokenEndpoint = "https://${oidcDomain}/application/o/token/";
  oidcAuthorizationEndpoint = "https://${oidcDomain}/application/o/authorize/";
  clientId = "cTWcU0CyVpSKtu6IbzLqxRuoC0Ykjtum5jICbaRR";
in {
  sops.secrets = {
    "netbird-turn-password" = {
      owner = "turnserver";
      mode = "0400";
    };
    "netbird-envirnoment-file" = {};
    "netbird-data-store-encryption-key" = {};
    "netbird-relay-secret" = {};
    "netbird-relay-secret-container-file" = {};
    "netbird-authentik-sa-password" = {};
  };

  services.netbird.server = {
    enable = true;
    enableNginx = true;
    domain = netbirdDomain;

    coturn = {
      enable = true;
      domain = netbirdDomain;
      passwordFile = "${config.sops.secrets."netbird-turn-password".path}";
    };

    dashboard = {
      package = pkgs-unstable.netbird-dashboard;
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      managementServer = "https://${netbirdDomain}";
      settings = {
        AUTH_AUDIENCE = clientId;
        AUTH_AUTHORITY = oidcIssuer;
        AUTH_CLIENT_ID = clientId;
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
        USE_AUTH0 = false;
      };
    };

    management = {
      package = pkgs-unstable.netbird-management;
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      turnDomain = netbirdDomain;
      dnsDomain = "dns.${netbirdDomain}";
      singleAccountModeDomain = netbirdDomain;
      oidcConfigEndpoint = oidcEndpoint;

      settings = {
        DataStoreEncryptionKey._secret = config.sops.secrets."netbird-data-store-encryption-key".path;

        DeviceAuthorizationFlow = {
          ProviderConfig = {
            Audience = clientId;
            ClientID = clientId;
          };
        };

        HttpConfig = {
          AuthAudience = clientId;
          AuthIssuer = oidcIssuer;
          AuthKeysLocation = oidcKeysLocation;
          AuthUserIDClaim = "sub";
          OIDCConfigEndpoint = oidcEndpoint;
        };

        IdpManagerConfig = {
          ManagerType = "authentik";

          ClientConfig = {
            ClientID = clientId;
            ClientSecret = "";
            Issuer = oidcIssuer;
            TokenEndpoint = oidcTokenEndpoint;
          };

          ExtraConfig = {
            Password._secret = config.sops.secrets."netbird-authentik-sa-password".path;
            Username = "Netbird";
          };
        };

        PKCEAuthorizationFlow.ProviderConfig = {
          Audience = clientId;
          ClientID = clientId;
          ClientSecret = "";
          Scope = "openid profile email offline_access api";
          AuthorizationEndpoint = oidcAuthorizationEndpoint;
          TokenEndpoint = oidcTokenEndpoint;
          RedirectURLs = ["http://localhost:53000"];
        };

        Relay = {
          Addresses = ["rels://${netbirdDomain}:33080"];
          CredentialsTTL = "24h";
          Secret._secret = config.sops.secrets."netbird-relay-secret".path;
        };

        Signal = {
          Proto = "https";
          URI = "${netbirdDomain}:443";
        };

        StoreConfig = {
          Engine = "postgres";
        };

        TURNConfig = {
          Secret._secret = config.sops.secrets."netbird-turn-password".path;
          CredentialsTTL = "12h";
          TimeBasedCredentials = false;
          Turns = [
            {
              Password._secret = config.sops.secrets."netbird-turn-password".path;
              Proto = "udp";
              URI = "turn:${netbirdDomain}:3478";
              Username = "netbird";
            }
          ];
        };
      };
    };

    signal = {
      package = pkgs-unstable.netbird-signal;
      enable = true;
      port = 10000;
      domain = netbirdDomain;
      enableNginx = true;
    };
  };

  # Run the Netbird relay with TLS to allow relaying over TCP
  virtualisation.oci-containers.containers.netbird-relay = {
    image = "netbirdio/relay:latest";
    ports = [
      "33080:33080"
    ];
    volumes = [
      "/var/lib/acme/${netbirdDomain}/:/certs:ro"
    ];
    environment = {
      NB_LOG_LEVEL = "info";
      NB_LISTEN_ADDRESS = ":33080";
      NB_EXPOSED_ADDRESS = "rels://${netbirdDomain}:33080";
      NB_TLS_CERT_FILE = "/certs/fullchain.pem";
      NB_TLS_KEY_FILE = "/certs/key.pem";
    };
    environmentFiles = [
      config.sops.secrets."netbird-relay-secret-container-file".path
    ];
  };

  # Make the env available to the systemd service
  systemd.services.netbird-management.serviceConfig = {
    EnvironmentFile = config.sops.secrets."netbird-envirnoment-file".path;
  };

  # Override ACME settings to get a cert
  services.nginx.virtualHosts = lib.mkMerge [
    {
      "${netbirdDomain}" = {
        enableACME = true;
        forceSSL = true;
      };
    }
  ];

  networking.firewall = {
    allowedTCPPorts = [80 443 3478 10000 33080];
    allowedUDPPorts = [3478 5349 33080];
    allowedUDPPortRanges = [
      {
        from = 40000;
        to = 40050;
      }
    ];
  };
}
