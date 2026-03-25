# Matrix sub-module — Synapse homeserver with MAS, PostgreSQL, ZFS, and signing keys.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix;
  pg = config.services.postgresql;
  postgresqlEnabled = pg.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;

  dbName = "matrix-synapse";
  dbOwner = "matrix-synapse";
in {
  config = lib.mkIf cfg.synapse.enable {
    assertions = [
      {
        assertion = postgresqlEnabled;
        message = "Matrix Synapse requires PostgreSQL (homelab.services.postgresql.enable)";
      }
    ];
    homelab = {
      zfs = {
        datasets = lib.mkIf cfg.synapse.zfs.enable {
          matrix-synapse = {
            enable = true;

            inherit (cfg.synapse.zfs.dataDir) dataset properties;

            mountpoint = cfg.synapse.dataDir;
            requiredBy = ["matrix-synapse.service"];

            restic = {
              enable = true;
            };
          };

          matrix-synapse-media = {
            enable = true;

            inherit (cfg.synapse.zfs.mediaDir) dataset properties;

            mountpoint = cfg.synapse.mediaDir;
            requiredBy = ["matrix-synapse.service"];

            restic = {
              enable = true;
            };
          };
        };
      };
    };

    services = {
      matrix-synapse = {
        enable = true;

        inherit (cfg.synapse) dataDir;

        settings = {
          media_store_path = cfg.synapse.mediaDir;
          server_name = cfg.rootDomain;
          public_baseurl = "https://${cfg.rootDomain}";

          listeners = [
            {
              port = cfg.synapse.listenPort;
              bind_addresses = cfg.synapse.listenAddress;
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

          # Connect via Unix socket (no password needed with peer auth)
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
            endpoint = "https://mas.${cfg.rootDomain}";
            secret_path = config.sops.secrets."matrix/synapse/mas-secret".path;
          };

          user_directory = {
            enabled = true;
            search_all_users = true;
            prefer_local_users = true;
            exclude_remote_users = false;
            show_locked_users = true;
          };

          # MSC3266: room summary API, MSC4222: sliding sync, MSC4140: delayed events
          experimental_features = {
            msc3266_enabled = true;
            msc4222_enabled = true;
            msc4140_enabled = true;
          };

          max_event_delay_duration = "24h";

          rc_message = {
            per_second = 0.5;
            burst_count = 30;
          };

          rc_delayed_event_mgmt = {
            per_second = 1;
            burst_count = 20;
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

                binds =
                  map (addr: {
                    host = addr;
                    inherit (cfg.synapse.mas.http.web) port;
                  })
                  cfg.synapse.mas.http.web.bindAddresses;
              }
              {
                name = "internal";
                resources = [
                  {
                    name = "health";
                  }
                ];
                binds =
                  map (addr: {
                    host = addr;
                    inherit (cfg.synapse.mas.http.health) port;
                  })
                  cfg.synapse.mas.http.health.bindAddresses;
                proxy_protocol = false;
              }
            ];

            inherit (cfg.synapse.mas.http) trusted_proxies;
            public_base = "https://mas.${cfg.rootDomain}";
          };

          matrix = {
            homeserver = cfg.rootDomain;
            endpoint = "https://${cfg.rootDomain}";
            secret_file = config.sops.secrets."matrix/mas/matrix-secret".path;
          };

          # Passwords disabled — all auth flows via upstream OIDC (Authentik)
          passwords = {
            enabled = false;
          };
        };

        extraConfigFiles = [
          config.sops.secrets."matrix/mas/upstream-oauth2.config".path
          config.sops.secrets."matrix/mas/secrets.config".path
        ];
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
          environment = {
            PGPORT = toString (pg.settings.port or 5432);
          };

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
            ++ lib.optionals cfg.synapse.zfs.enable [
              "zfs-dataset-matrix-synapse.service"
              "zfs-dataset-matrix-synapse-media.service"
            ];
          requires = lib.optionals cfg.synapse.zfs.enable [
            "zfs-dataset-matrix-synapse.service"
            "zfs-dataset-matrix-synapse-media.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown matrix-synapse:matrix-synapse \
                ${toString cfg.synapse.dataDir} \
                ${toString cfg.synapse.mediaDir}
            '';
          };
        };

        matrix-synapse = lib.mkMerge [
          {
            unitConfig = {
              RequiresMountsFor = [
                cfg.synapse.dataDir
                cfg.synapse.mediaDir
              ];
            };
          }

          (lib.mkIf cfg.synapse.zfs.enable {
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

      tmpfiles = {
        rules = [
          "d ${toString cfg.synapse.dataDir} 0750 matrix-synapse matrix-synapse -"
          "d ${toString cfg.synapse.mediaDir} 0750 matrix-synapse matrix-synapse -"
          "z ${toString cfg.synapse.dataDir} 0750 matrix-synapse matrix-synapse -"
          "z ${toString cfg.synapse.mediaDir} 0750 matrix-synapse matrix-synapse -"
        ];
      };
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !cfg.synapse.zfs.enable
      ) {
        persistence = {
          "/nix/persist" = {
            directories = [
              cfg.synapse.dataDir
              cfg.synapse.mediaDir
            ];
          };
        };
      };

    users = {
      users = {
        matrix-authentication-service = {
          uid = cfg.synapse.mas.userId;
        };
      };

      groups = {
        matrix-authentication-service = {
          gid = cfg.synapse.mas.groupId;
        };
      };
    };
  };
}
