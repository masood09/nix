{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix-synapse;
  pg = config.services.postgresql;
  postgresqlEnabled = pg.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;
  caddyEnabled = config.services.caddy.enable;

  dbName = "matrix-synapse";
  dbOwner = "matrix-synapse";

  webDomain = "https://${cfg.serverUrl}";

  clientConfig."m.homeserver".base_url = webDomain;
  serverConfig."m.server" = "${cfg.serverUrl}:443";
in {
  imports = [
    ./matrix-authentication-service.nix
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab.zfs.datasets = lib.mkIf cfg.zfs.enable {
      matrix-synapse = {
        enable = true;

        inherit (cfg.zfs.dataDir) dataset properties;

        mountpoint = cfg.dataDir;
        requiredBy = ["matrix-synapse.service"];

        restic = {
          enable = true;
        };
      };

      matrix-synapse-media = {
        enable = true;

        inherit (cfg.zfs.mediaDir) dataset properties;

        mountpoint = cfg.mediaDir;
        requiredBy = ["matrix-synapse.service"];

        restic = {
          enable = true;
        };
      };
    };

    services = {
      matrix-synapse = {
        enable = true;

        inherit (cfg) dataDir;

        settings = {
          media_store_path = cfg.mediaDir;
          server_name = cfg.serverName;
          public_baseurl = webDomain;

          listeners = [
            {
              port = cfg.listenPort;
              bind_addresses = cfg.listenAddress;
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [
                    "client"
                    "federation"
                  ];
                  compress = true;
                }
              ];
            }
          ];

          database = {
            name = "psycopg2";
            args = {
              user = dbOwner;
              database = dbName;
              host = "/run/postgresql";
            };
          };

          matrix_authentication_service = {
            enabled = true;
            endpoint = "https://mas.${config.networking.domain}";
            secret_path = config.sops.secrets."matrix-synapse/matrix-authentication-service.secret".path;
          };

          user_directory = {
            enabled = true;
            search_all_users = true;
            prefer_local_users = true;
            exclude_remote_users = false;
            show_locked_users = true;
          };
        };
      };

      matrix-authentication-service = {
        enable = true;

        settings = {
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

          passwords = {
            enabled = false;
          };
        };

        extraConfigFiles = [
          config.sops.secrets."matrix-authentication-service/upstream-oauth2.config".path
          config.sops.secrets."matrix-authentication-service/secrets.config".path
        ];
      };

      caddy = lib.mkIf (caddyEnabled && cfg.enableCaddy) {
        virtualHosts = {
          "${cfg.serverName}" = {
            extraConfig = ''
              respond /.well-known/matrix/server `${builtins.toJSON serverConfig}`
              respond /.well-known/matrix/client `${builtins.toJSON clientConfig}`
            '';
          };

          "${cfg.serverUrl}" = {
            useACMEHost = cfg.serverName;
            extraConfig = ''
              @masAuth path_regexp masAuth ^/_matrix/client/(.*)/(login|logout|refresh)$
              reverse_proxy @masAuth http://127.0.0.1:8910

              @synapse path /_matrix* /_synapse/client* /_synapse/mas*
              reverse_proxy @synapse http://127.0.0.1:${toString cfg.listenPort}
            '';
          };

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
          dbName
          "matrix-authentication-service"
        ];
      };
    };

    systemd = {
      services = {
        matrix-synapse-init-db = lib.mkIf postgresqlEnabled {
          description = "Matrix Synapse: ensure Postgres database exists with locale C";

          # Tie it to Synapse startup
          wantedBy = ["matrix-synapse.service"];
          before = ["matrix-synapse.service"];

          requires = ["postgresql.service"];
          after = ["postgresql.service"];

          serviceConfig = {
            User = "postgres";
            Group = "postgres";
            Type = "oneshot";
            RemainAfterExit = true;
          };

          # Provide psql on PATH
          path = [
            pg.package
            pkgs.gnugrep
            pkgs.coreutils
          ];

          # Ensure we connect to the right port (in case you customized it)
          environment.PGPORT = toString (pg.settings.port or 5432);

          script = ''
            set -euo pipefail

            # If PostgreSQL is in standby mode, don't perform any setup
            if [[ -f "${pg.dataDir}/standby.signal" ]]; then
              echo "Skipping DB init because PostgreSQL is in standby mode"
              exit 0
            fi

            # Wait for PostgreSQL to accept connections and not be in recovery.
            while true; do
              if ! systemctl is-active --quiet postgresql.service; then
                echo "PostgreSQL stopped while waiting; aborting"
                exit 1
              fi

              if psql -d postgres -v ON_ERROR_STOP=1 -tAc "SELECT 1" >/dev/null 2>&1; then
                if psql -d postgres -v ON_ERROR_STOP=1 -tAc "SELECT pg_is_in_recovery()" | grep -qx f; then
                  break
                fi
              fi

              sleep 0.1
            done

            # If DB exists, do nothing
            if psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${dbName}'" | grep -qx 1; then
              echo "DB '${dbName}' already exists; nothing to do."
              exit 0
            fi

            # Ensure role exists (idempotent)
            if ! psql -tAc "SELECT 1 FROM pg_roles WHERE rolname = '${dbOwner}'" | grep -qx 1; then
              echo "Creating role '${dbOwner}'"
              psql -v ON_ERROR_STOP=1 -c "CREATE ROLE \"${dbOwner}\" LOGIN;"
            fi

            echo "Creating DB '${dbName}' with OWNER '${dbOwner}' and locale C"
            psql -v ON_ERROR_STOP=1 -c \
              "CREATE DATABASE \"${dbName}\" WITH OWNER \"${dbOwner}\" TEMPLATE template0 LC_COLLATE 'C' LC_CTYPE 'C';"

            echo "Done."
          '';
        };

        matrix-synapse-permissions = {
          description = "Fix Matrix Synapse dataDir ownership/permissions";
          wantedBy = ["matrix-synapse.service"];
          before = ["matrix-synapse.service"];

          after =
            ["systemd-tmpfiles-setup.service" "local-fs.target"]
            ++ lib.optionals cfg.zfs.enable [
              "zfs-dataset-matrix-synapse.service"
              "zfs-dataset-matrix-synapse-media.service"
            ];
          requires = lib.optionals cfg.zfs.enable [
            "zfs-dataset-matrix-synapse.service"
            "zfs-dataset-matrix-synapse-media.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown matrix-synapse:matrix-synapse \
                ${toString cfg.dataDir} \
                ${toString cfg.mediaDir}
            '';
          };
        };

        matrix-synapse = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [
                cfg.dataDir
                cfg.mediaDir
              ];
            };
          }

          (lib.mkIf cfg.zfs.enable {
            requires =
              [
                "zfs-dataset-matrix-synapse.service"
                "zfs-dataset-matrix-synapse-media.service"
              ]
              ++ lib.optionals postgresqlEnabled [
                "postgresql.target"
              ];

            after =
              [
                "zfs-dataset-matrix-synapse.service"
                "zfs-dataset-matrix-synapse-media.service"
              ]
              ++ lib.optionals postgresqlEnabled [
                "postgresql.target"
              ];
          })
        ];

        matrix-authentication-service = {
          after =
            lib.optional postgresqlEnabled "postgresql.service"
            ++ lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit;

          wants =
            lib.optional postgresqlEnabled "postgresql.service"
            ++ lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit;
        };
      };

      tmpfiles.rules = [
        "d ${toString cfg.dataDir} 0750 matrix-synapse matrix-synapse -"
        "d ${toString cfg.mediaDir} 0750 matrix-synapse matrix-synapse -"
        "z ${toString cfg.dataDir} 0750 matrix-synapse matrix-synapse -"
        "z ${toString cfg.mediaDir} 0750 matrix-synapse matrix-synapse -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !cfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          cfg.dataDir
          cfg.mediaDir
        ];
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
