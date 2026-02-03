{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  lokiCfg = homelabCfg.services.loki;
  caddyEnabled = config.services.caddy.enable;

  lokiDataDir = lib.removeSuffix "/" (toString lokiCfg.dataDir);
  lokiPath = p: "${lokiDataDir}/${p}";
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf lokiCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.loki = lib.mkIf lokiCfg.zfs.enable {
      inherit (lokiCfg.zfs) dataset properties;

      enable = true;
      mountpoint = lokiDataDir;

      requiredBy = [
        "loki.service"
      ];

      restic = {
        enable = false;
      };
    };

    services = {
      loki = {
        enable = true;

        configuration = {
          auth_enabled = false;

          server = {
            http_listen_address = lokiCfg.listenAddress;
            http_listen_port = lokiCfg.listenPort;
          };

          common = {
            ring = {
              instance_addr = lokiCfg.listenAddress;

              kvstore = {
                store = "inmemory";
              };
            };

            replication_factor = 1;
            path_prefix = lokiDataDir;
          };

          schema_config = {
            configs = [
              {
                from = "2026-01-20";
                store = "tsdb";
                object_store = "filesystem";
                schema = "v13";

                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
          };

          storage_config = {
            tsdb_shipper = {
              active_index_directory = lokiPath "index";
              cache_location = lokiPath "index_cache";
              cache_ttl = "24h";
            };

            filesystem = {
              directory = lokiPath "chunks";
            };
          };

          compactor = {
            working_directory = lokiPath "compactor";
            retention_enabled = true;
            retention_delete_worker_count = 10;
            retention_delete_delay = "2h";
            delete_request_store = "filesystem";
          };

          limits_config = {
            # Default for anything that doesn't match a retention_stream selector
            retention_period = lokiCfg.retentionPeriod.default;

            retention_stream = [
              {
                selector = "{level=\"debug\"}";
                priority = 40;
                period = lokiCfg.retentionPeriod.debug;
              }
              {
                selector = "{level=\"info\"}";
                priority = 30;
                period = lokiCfg.retentionPeriod.info;
              }
              {
                selector = "{level=\"warn\"}";
                priority = 20;
                period = lokiCfg.retentionPeriod.warn;
              }
              {
                selector = "{level=\"error\"}";
                priority = 10;
                period = lokiCfg.retentionPeriod.error;
              }
            ];
          };

          ingester = {
            autoforget_unhealthy = true;
          };
        };
      };

      # Caddy reverse proxy with auth except /ready
      caddy = lib.mkIf caddyEnabled {
        environmentFile = config.sops.secrets."caddy.env".path;

        virtualHosts = {
          "${lokiCfg.webDomain}" = {
            useACMEHost = config.networking.domain;

            extraConfig = ''
              route {
                # No auth for readiness
                handle /ready* {
                  reverse_proxy http://${lokiCfg.listenAddress}:${toString lokiCfg.listenPort}
                }

                # Everything else requires basic auth
                handle {
                  basic_auth {
                    {$LOKI_USERNAME} {$LOKI_BCRYPT}
                  }
                  reverse_proxy http://${lokiCfg.listenAddress}:${toString lokiCfg.listenPort}
                }
              }
            '';
          };
        };
      };
    };

    users.users = {
      loki.uid = lokiCfg.userId;
    };

    users.groups = {
      loki.gid = lokiCfg.groupId;
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        loki = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [lokiDataDir];
            };

            requires = ["loki-permissions.service"];
            after = ["loki-permissions.service"];
          }

          (lib.mkIf lokiCfg.zfs.enable {
            requires = ["zfs-dataset-loki.service"];
            after = ["zfs-dataset-loki.service"];
          })
        ];

        loki-permissions = {
          description = "Fix Loki dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["loki.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals lokiCfg.zfs.enable ["zfs-dataset-loki.service"];
          requires =
            lib.optionals lokiCfg.zfs.enable ["zfs-dataset-loki.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown loki:loki ${lokiDataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${lokiDataDir} 0700 loki loki -"
        "z ${lokiDataDir} 0700 loki loki -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !lokiCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          lokiDataDir
        ];
      };
  };
}
