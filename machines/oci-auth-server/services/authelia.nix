{ config, lib, ... }:
{
  sops.secrets = {
    "authelia-jwt-secret" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-storage-encryption-key" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-jwks" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-hmac-secret" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-session-secret" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-lldap-password" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-smtp-password" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-headscale-oidc-client-secret" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-immich-oidc-client-secret" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
    "authelia-karakeep-oidc-client-secret" = {
      owner = "authelia-mantannest";
      sopsFile = ./../../../secrets/oci-auth-server.yaml;
    };
  };

  services = {
    authelia.instances.mantannest = {
      enable = true;

      settings = {
        theme = "dark";
        default_2fa_method = "webauthn";

        authentication_backend.ldap = {
          address = "ldap://ldap-server.publicsubnet.ocivcn.oraclevcn.com:3890";
          implementation = "lldap";
          timeout = "5s";
          start_tls = false;
          base_dn = "dc=mantannest,dc=com";
          additional_users_dn = "OU=people";
          users_filter = "(&({username_attribute}={input})(objectClass=person))";
          additional_groups_dn = "OU=groups";
          groups_filter = "(member={dn})";
          user = "uid=authelia,ou=people,dc=mantannest,dc=com";

          attributes = {
            distinguished_name = "distinguishedName";
            username = "uid";
            mail = "mail";
            member_of = "memberOf";
            group_name = "cn";
          };
        };

        access_control = {
          default_policy = "deny";

          # We want this rule to be low priority so it doesn't override the others
          rules = lib.mkAfter [
            {
              domain = "*.mantannest.com";
              policy = "two_factor";
            }
          ];
        };

        storage.postgres = {
          address = "unix:///run/postgresql";
          database = "authelia-mantannest";
          username = "authelia-mantannest";
        };

        session = {
          redis.host = "/var/run/redis-oci-auth/redis.sock";
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
          username = "ocid1.user.oc1..aaaaaaaasqsnfpwp6k7f4pn4bycnomrny4hhilksa5yh5jauo6npxga7mhxa@ocid1.tenancy.oc1..aaaaaaaaabdnzyn2ijeptsm5hlfr74d4mwc5qnngv3nmhyzjqdvtv54vxk3q.7i.com";
          sender = "auth@mantannest.com";
        };

        log.level = "debug";

        identity_providers.oidc = {
          claims_policies = {
            # headscale.id_token = [
              # "email"
              # "groups"
            # ];

            headscale = {
              id_token = [
                "email"
                "email_verified"
                "preferred_username"
                "name"
                "given_name"
                "family_name"
                "groups"
              ];
            };

            karakeep.id_token = [ "email" ];
            opkssh.id_token = [ "email" ];
          };

          clients = [
            {
              client_id = "authelia-headscale";
              claims_policy = "headscale";
            }
          ];

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

        # totp = {
        #   disable = false;
        #   issuer = "authelia.com";
        #   algorithm = "sha1";
        #   digits = 6;
        #   period = 30;
        #   skew = 1;
        #   secret_size = 32;
        # };

        webauthn = {
          enable_passkey_login = true;
        };

        server.address = "tcp://127.0.0.1:9091/";

        regulation = {
          max_retries = 3;
          find_time = "2m";
          ban_time = "5m";
        };
      };

      settingsFiles = [ ./files/authelia_oidc_clients.yaml ];

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
        AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = secrets."authelia-smtp-password".path;
      };
    };
  };

  # Give Authelia access to the Redis socket
  users.users."authelia-mantannest".extraGroups = ["redis-oci-auth"];
}
