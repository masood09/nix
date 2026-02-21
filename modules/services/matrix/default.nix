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
  caddyEnabled = config.services.caddy.enable;

  dbName = "matrix-synapse";
  dbOwner = "matrix-synapse";

  clientConfig = {
    "m.homeserver".base_url = "https://${cfg.rootDomain}";
    "org.matrix.msc4143.rtc_foci" = [
      {
        type = "livekit";
        livekit_service_url = "https://rtc.${cfg.rootDomain}";
      }
    ];
  };

  serverConfig."m.server" = "${cfg.rootDomain}:443";
in {
  imports = [
    ./mas-service.nix
    ./options.nix
  ];

  config = {
    homelab.zfs.datasets = lib.mkIf (cfg.synapse.enable && cfg.synapse.zfs.enable) {
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

    services = {
      matrix-synapse = lib.mkIf cfg.synapse.enable {
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

      "lk-jwt-service" = lib.mkIf cfg.rtc.enable {
        enable = true;
        keyFile = config.sops.secrets."matrix/lk-jwt-service/keys".path;
        inherit (cfg.rtc."lk-jwt-service") port;
        livekitUrl = "wss://rtc.${cfg.rootDomain}/livekit/sfu";
      };

      livekit = lib.mkIf cfg.rtc.enable {
        enable = true;
        keyFile = config.sops.secrets."matrix/lk-jwt-service/keys".path;
        openFirewall = true;

        settings = {
          bind_addresses = cfg.rtc.livekit.bindAddress;
          inherit (cfg.rtc.livekit.ports) port;

          rtc = {
            tcp_port = cfg.rtc.livekit.ports.tcpPort;
            port_range_start = cfg.rtc.livekit.ports.rtcPortRangeStart;
            port_range_end = cfg.rtc.livekit.ports.rtcPortRangeEnd;
            use_external_ip = cfg.rtc.livekit.rtcExternalIP;
          };

          room = {
            auto_create = false;
          };

          logging = {
            level = "info";
          };

          turn = {
            enabled = false;
          };
        };
      };

      matrix-authentication-service = lib.mkIf cfg.synapse.enable {
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

          passwords = {
            enabled = false;
          };
        };

        extraConfigFiles = [
          config.sops.secrets."matrix/mas/upstream-oauth2.config".path
          config.sops.secrets."matrix/mas/secrets.config".path
        ];
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.rootDomain}" = lib.mkIf (cfg.synapse.enable && cfg.synapse.enableCaddy) {
            useACMEHost = cfg.rootDomain;
            extraConfig = ''
              # Server discovery (no CORS required, but harmless)
              handle /.well-known/matrix/server {
                header Content-Type application/json
                respond `${builtins.toJSON serverConfig}` 200
              }

              # Client discovery: MUST include CORS for some validators / browsers
              handle /.well-known/matrix/client {
                header Content-Type application/json
                header Access-Control-Allow-Origin "*"
                header Access-Control-Allow-Methods "GET, OPTIONS"
                header Access-Control-Allow-Headers "Origin, Accept, Content-Type, Authorization"

                # Optional: make preflight happy if anyone ever OPTIONS it
                @options method OPTIONS
                respond @options 204

                respond `${builtins.toJSON clientConfig}` 200
              }

              @masAuth path_regexp masAuth ^/_matrix/client/(.*)/(login|logout|refresh)$
              reverse_proxy @masAuth http://127.0.0.1:${toString cfg.synapse.mas.http.web.port}

              @health path /-/health
              reverse_proxy @health http://127.0.0.1:${toString cfg.synapse.listenPort} {
                rewrite /health
              }

              @synapse path /_matrix* /_synapse/client* /_synapse/mas*
              reverse_proxy @synapse http://127.0.0.1:${toString cfg.synapse.listenPort}
            '';
          };

          "rtc.${cfg.rootDomain}" = lib.mkIf cfg.rtc.enable {
            useACMEHost = cfg.rootDomain;
            extraConfig = ''
              handle /sfu/get* {
                reverse_proxy 127.0.0.1:${toString cfg.rtc."lk-jwt-service".port}
              }

              handle_path /livekit/sfu* {
                reverse_proxy 127.0.0.1:${toString cfg.rtc.livekit.ports.port}
              }
            '';
          };

          "mas.${cfg.rootDomain}" = lib.mkIf (cfg.synapse.enable && cfg.synapse.enableCaddy) {
            useACMEHost = cfg.rootDomain;
            extraConfig = ''
              @health path /-/health
              reverse_proxy @health http://127.0.0.1:${toString cfg.synapse.mas.http.health.port} {
                rewrite /health
              }

              reverse_proxy http://127.0.0.1:${toString cfg.synapse.mas.http.web.port}
            '';
          };
        };
      };

      postgresql = lib.mkIf (postgresqlEnabled && cfg.synapse.enable) {
        ensureDatabases = ["matrix-authentication-service"];
        ensureUsers = [
          {
            name = "matrix-authentication-service";
            ensureDBOwnership = true;
          }
        ];
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled && cfg.synapse.enable) {
        databases = [
          dbName
          "matrix-authentication-service"
        ];
      };
    };

    security = lib.mkIf (caddyEnabled && ((cfg.synapse.enableCaddy && cfg.synapse.enable) || cfg.rtc.enable)) {
      acme.certs."${cfg.rootDomain}" = {
        extraDomainNames = [
          "${cfg.rootDomain}"
          "*.${cfg.rootDomain}"
        ];
      };
    };

    systemd = {
      services = {
        "lk-jwt-service" = lib.mkIf cfg.rtc.enable {
          environment = {
            LIVEKIT_FULL_ACCESS_HOMESERVERS = cfg.rootDomain;
            LIVEKIT_JWT_BIND = "127.0.0.1:${toString cfg.rtc."lk-jwt-service".port}";
            LIVEKIT_JWT_PORT = lib.mkForce "";
          };
        };

        matrix-synapse-init-db = lib.mkIf (postgresqlEnabled && cfg.synapse.enable) {
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

        matrix-synapse-permissions = lib.mkIf cfg.synapse.enable {
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

        matrix-synapse = lib.mkIf cfg.synapse.enable (lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
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
        ]);

        matrix-authentication-service = lib.mkIf cfg.synapse.enable {
          after =
            lib.optional postgresqlEnabled "postgresql.service"
            ++ lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit;

          wants =
            lib.optional postgresqlEnabled "postgresql.service"
            ++ lib.optional config.services.matrix-synapse.enable config.services.matrix-synapse.serviceUnit;
        };
      };

      tmpfiles.rules = lib.mkIf cfg.synapse.enable [
        "d ${toString cfg.synapse.dataDir} 0750 matrix-synapse matrix-synapse -"
        "d ${toString cfg.synapse.mediaDir} 0750 matrix-synapse matrix-synapse -"
        "z ${toString cfg.synapse.dataDir} 0750 matrix-synapse matrix-synapse -"
        "z ${toString cfg.synapse.mediaDir} 0750 matrix-synapse matrix-synapse -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && cfg.synapse.enable
        && !cfg.synapse.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          cfg.synapse.dataDir
          cfg.synapse.mediaDir
        ];
      };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts =
        lib.optionals cfg.synapse.enable [
          cfg.synapse.listenPort
          cfg.synapse.mas.http.web.port
          cfg.synapse.mas.http.health.port
        ]
        ++ lib.optionals cfg.rtc.enable [
          cfg.rtc.livekit.ports.tcpPort
        ];

      allowedUDPPortRanges = lib.optionals cfg.rtc.enable [
        {
          from = cfg.rtc.livekit.ports.rtcPortRangeStart;
          to = cfg.rtc.livekit.ports.rtcPortRangeEnd;
        }
      ];
    };

    users = lib.mkIf cfg.synapse.enable {
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
