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
  clientId = "sr60iFh1hxJNFawnM5dPHEfl2LG4oyZ9xBsNXHmP";
in {
  sops.secrets = {
    "netbird-turn-password" = {
      owner = "turnserver";
      mode = "0400";
    };
    "netbird-authentik-password" = {};
    "netbird-envirnoment-file" = {};
  };

  services.netbird.server = {
    enable = true;
    enableNginx = true;
    domain = netbirdDomain;

    management = {
      # package = pkgs-unstable.netbird-management;
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      turnDomain = netbirdDomain;
      dnsDomain = "dns.${netbirdDomain}";
      singleAccountModeDomain = netbirdDomain;
      disableSingleAccountMode = false;
      oidcConfigEndpoint = "https://${oidcDomain}/application/o/netbird/.well-known/openid-configuration";

      settings = {
        TURNConfig = {
          Turns = [
            {
              Proto = "udp";
              URI = "turn:turn.${netbirdDomain}:3478";
              Username = "netbird";
              Password._secret = "${config.sops.secrets."netbird-turn-password".path}";
            }
          ];

          Secret._secret = "${config.sops.secrets."netbird-turn-password".path}";
        };

        DataStoreEncryptionKey = null;

        StoreConfig = {
          Engine = "postgres";
        };

        HttpConfig = {
          AuthAudience = clientId;
          AuthUserIDClaim = "sub";
          AuthIssuer = "https://${oidcDomain}/application/o/netbird/";
          AuthKeysLocation = "https://${oidcDomain}/application/o/netbird/jwks/";
        };

        IdpManagerConfig = {
          ManagerType = "authentik";
          ClientConfig = {
            Issuer = "https://${oidcDomain}/application/o/netbird/";
            ClientID = clientId;
            TokenEndpoint = "https://${oidcDomain}/application/o/token/";
            ClientSecret = "";
          };
          ExtraConfig = {
            Password._secret = "${config.sops.secrets."netbird-authentik-password".path}";
            Username = "Netbird";
          };
        };

        PKCEAuthorizationFlow.ProviderConfig = {
          Audience = clientId;
          ClientID = clientId;
          ClientSecret = "";
          Scope = "openid profile email offline_access api";
          AuthorizationEndpoint = "https://${oidcDomain}/application/o/authorize/";
          TokenEndpoint = "https://${oidcDomain}/application/o/token/";
          RedirectURLs = [
            "http://localhost:53000"
          ];
        };
      };
    };

    signal = {
      # package = pkgs-unstable.netbird-signal;
      enable = true;
      port = 10000;
      domain = netbirdDomain;
      enableNginx = true;
    };

    dashboard = {
      package = pkgs-unstable.netbird-dashboard;
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      managementServer = "https://${netbirdDomain}";
      settings = {
        AUTH_AUTHORITY = "https://${oidcDomain}/application/o/netbird/";
        AUTH_SUPPORTED_SCOPES = "openid profile email offline_access api";
        AUTH_AUDIENCE = clientId;
        AUTH_CLIENT_ID = clientId;
        USE_AUTH0 = "false";
      };
    };

    coturn = {
      enable = true;
      passwordFile = "${config.sops.secrets."netbird-turn-password".path}";
      domain = netbirdDomain;
    };
  };

  # Make the env available to the systemd service
  systemd.services.netbird-management.serviceConfig = {
    EnvironmentFile = "${config.sops.secrets."netbird-envirnoment-file".path}";
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
