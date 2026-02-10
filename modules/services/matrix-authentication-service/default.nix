{
  config,
  lib,
  pkgs,
  ...
}: let
  caddyEnabled = config.services.caddy.enable;
  postgresqlEnabled = config.services.postgresql.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;
in {
  imports = [
    ./service.nix
  ];

  config = {
    environment.systemPackages = with pkgs; [
      matrix-authentication-service
    ];

    services = {
      matrix-authentication-service = {
        enable = true;

        settings = {
          email = {
            from = "\"Matrix Authentication Service\" <no-reply@mantannest.com>";
            reply_to = "\"Masood Ahmed\" <mas@ahmedmasood.com>";
            transport = "smtp";
            mode = "starttls";
            port = 587;
          };

          http = {
            listeners = [
              {
                name = "web";
                proxy_protocol = false;
                resources = [
                  {
                    name = "discovery";
                  }
                  {
                    name = "human";
                  }
                  {
                    name = "oauth";
                  }
                  {
                    name = "compat";
                  }
                  {
                    name = "graphql";
                  }
                  {
                    name = "assets";
                  }
                ];
                binds = [
                  {
                    address = "127.0.0.1:8910";
                  }
                ];
              }
              {
                name = "internal";
                resources = [
                  {
                    name = "health";
                  }
                ];
                binds = [
                  {
                    host = "localhost";
                    port = 8911;
                  }
                ];
                proxy_protocol = false;
              }
            ];

            trusted_proxies = ["127.0.0.1"];
            public_base = "https://mas.${config.networking.domain}";
          };

          matrix = {
            homeserver = config.networking.domain;
            endpoint = "http://localhost:${toString config.homelab.services.matrix-synapse.listenPort}";
            secret_file = config.sops.secrets."matrix-authentication-service/matrix.secret".path;
          };
        };

        extraConfigFiles = [
          config.sops.secrets."matrix-authentication-service/email.config".path
          config.sops.secrets."matrix-authentication-service/upstream-oauth2.config".path
          config.sops.secrets."matrix-authentication-service/secrets.config".path
        ];
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "mas.${config.networking.domain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:8910
            '';
          };
        };
      };

      postgresql = lib.mkIf postgresqlEnabled {
        ensureDatabases = ["matrix-authentication-service"];
        ensureUsers = [
          {
            name = "matrix-authentication-service";
            ensureDBOwnership = true;
          }
        ];
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled) {
        databases = [
          "matrix-authentication-service"
        ];
      };
    };

    systemd = {
      services = {
        matrix-authentication-service = {
          after =
            lib.optional postgresqlEnabled "postgresql.service"
            ++ lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit;

          wants =
            lib.optional postgresqlEnabled "postgresql.service"
            ++ lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit;
        };
      };
    };

    users = {
      users = {
        matrix-authentication-service = {
          uid = 3010;
        };
      };

      groups = {
        matrix-authentication-service = {
          gid = 3010;
        };
      };
    };
  };
}
