{ config, lib, ... }:
{
  sops.secrets = {
    "authelia-jwt-secret" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-storage-encryption-key" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-jwks" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-hmac-secret" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-session-secret" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-lldap-password" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-smtp-password" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-smtp-username" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-immich-oidc-client-id" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-immich-oidc-client-secret" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-karakeep-oidc-client-id" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-karakeep-oidc-client-secret" = {
      owner = "authelia";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
  };

  users.groups.authelia = {};

  users.users.authelia = {
    name = "authelia";
    group = "authelia";
    description = "authelia server user";
    isSystemUser = true;
  };

  services = {
    authelia.instances.mantannest = {
      enable = true;

      settings = {
        theme = "dark";

        authentication_backend.ldap = {
          address = "ldap://ldap-server.publicsubnet.ocivcn.oraclevcn.com:3890";
          base_dn = "dc=homelab,dc=mantannest,dc=com";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          groups_filter = "(member={dn})";
          user = "authelia";
        };

        access_control = {
          default_policy = "deny";
          # We want this rule to be low priority so it doesn't override the others
          rules = lib.mkAfter [
            {
              domain = "*.homelab.mantannest.com";
              policy = "one_factor";
            }
          ];
        };

        storage.postgres = {
          address = "unix:///run/postgresql";
          database = "authelia";
          username = "authelia";
        };

        session = {
          redis.host = "/var/run/redis-haddock/redis.sock";
          cookies = [
            {
              domain = "mantannest.com";
              authelia_url = "https://auth2.mantannest.com";
              # The period of time the user can be inactive for before the session is destroyed
              inactivity = "1M";
              # The period of time before the cookie expires and the session is destroyed
              expiration = "3M";
              # The period of time before the cookie expires and the session is destroyed
              # when the remember me box is checked
              remember_me = "1y";
            }
          ];
        };

        notifier.smtp = {
          address = "smtp://smtp.email.ca-toronto-1.oci.oraclecloud.com:587";
          sender = "auth@mantannest.com";
        };

        log.level = "info";

        identity_providers.oidc = {
          claims_policies = {
            karakeep.id_token = [ "email" ];
            opkssh.id_token = [ "email" ];
          };

          cors = {
            endpoints = [ "token" ];
            allowed_origins_from_client_redirect_uris = true;
          };

          authorization_policies.default = {
            default_policy = "one_factor";
            rules = [
              {
                policy = "deny";
                subject = "group:lldap_strict_readonly";
              }
            ];
          };
        };

        webauthn = {
          enable_passkey_login = true;
        };
      };

      settingsFiles = [ ./../../../files/authelia_oidc_clients.yaml ];

      secrets = with config.sops; {
        jwtSecretFile = secrets."authelia-jwt-secret".path;
        oidcIssuerPrivateKeyFile = secrets."authelia-jwks".path;
        oidcHmacSecretFile = secrets."authelia-hmac-secret".path;
        sessionSecretFile = secrets."authelia-session-secret".path;
        storageEncryptionKeyFile = secrets."authelia-storage-encryption-key".path;
      };

      environmentVariables = with config.sops; {
        AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE =
          secrets."authelia-lldap-password".path;
        AUTHELIA_NOTIFIER_SMTP_USERNAME_FILE = secrets."authelia-smtp-username".path;
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = secrets."authelia-smtp-password".path;
      };
    };
  };    
}
