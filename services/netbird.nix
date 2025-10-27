{ config, lib, ... }:

let
  domain = "mantannest.com";
  netbirdDomain = "netbird.${domain}";
  clientId = "sr60iFh1hxJNFawnM5dPHEfl2LG4oyZ9xBsNXHmP";
in
{
  sops.secrets = {
    "netbird-turn-password" = {
      owner = "turnserver";
      mode = "0400";
    };
    "netbird-data-store-encryption-key" = {};
    "netbird-relay-secret" = {};
    "netbird-relay-secret-container" = {};
    "netbird-setup-env" = {};
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

    signal = {
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
    };

    dashboard = {
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      settings = {
        AUTH_AUTHORITY = "https://auth.${domain}/application/o/netbird";
        AUTH_CLIENT_ID = clientId;
        AUTH_AUDIENCE = clientId;
      };
    };

    management = {
      enable = true;
      enableNginx = true;
      domain = netbirdDomain;
      turnDomain = netbirdDomain;
      # logLevel = "DEBUG";
      # singleAccountModeDomain = netbirdDomain;
      oidcConfigEndpoint = "https://auth.mantannest.com/application/o/netbird/.well-known/openid-configuration";

      settings = {
        # Signal.URI = "${netbirdDomain}:443";

        HttpConfig.AuthAudience = clientId;
        # IdpManagerConfig.ClientConfig.ClientID = clientId;
        # DeviceAuthorizationFlow.ProviderConfig = {
          # Audience = clientId;
          # ClientID = clientId;
        # };
        # PKCEAuthorizationFlow.ProviderConfig = {
          # Audience = clientId;
          # ClientID = clientId;
        # };

        TURNConfig = {
          Secret._secret = "${config.sops.secrets."netbird-turn-password".path}";
          CredentialsTTL = "12h";
          TimeBasedCredentials = false;
          Turns = [
            {
              Password._secret = "${config.sops.secrets."netbird-turn-password".path}";
              Proto = "udp";
              URI = "turn:${netbirdDomain}:3478";
              Username = "netbird";
            }
          ];
        };
        Relay = {
          Addresses = [ "rels://${netbirdDomain}:33080" ];
          CredentialsTTL = "24h";
          Secret._secret = "${config.sops.secrets."netbird-relay-secret".path}";
        };
        DataStoreEncryptionKey._secret = "${config.sops.secrets."netbird-data-store-encryption-key".path}";
      };
    };
  };

  # Make the env available to the systemd service
  systemd.services.netbird-management.serviceConfig = {
    EnvironmentFile = "${config.sops.secrets."netbird-setup-env".path}";
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
      "${config.sops.secrets."netbird-relay-secret-container".path}"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 80 443 3478 10000 33080 ];
  networking.firewall.allowedUDPPorts = [ 3478 5349 33080 ];
  networking.firewall.allowedUDPPortRanges = [{
    from = 40000;
    to = 40050;
  }]; # TURN ports
}
