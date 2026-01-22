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
  options.homelab.services.loki = {
    enable = lib.mkEnableOption "Whether to enable Loki.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "loki.mantannest.com";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/loki/";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 3100;
      type = lib.types.port;
    };

    userId = lib.mkOption {
      default = 3005;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3005;
      type = lib.types.ints.u16;
    };

    zfs = {
      enable = lib.mkEnableOption "Store Loki dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/loki";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "metadata";
        };
      };
    };
  };

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
            retention_period = "240h"; # 10d

            retention_stream = [
              {
                selector = "{level=\"debug\"}";
                priority = 40;
                period   = "24h";  # 1d
              }
              {
                selector = "{level=\"info\"}";
                priority = 30;
                period   = "240h"; # 10d (optional since it's the default)
              }
              {
                selector = "{level=\"warn\"}";
                priority = 20;
                period   = "720h"; # 30d
              }
              {
                selector = "{level=\"error\"}";
                priority = 10;
                period   = "1440h"; # 60d
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
        environmentFile = config.sops.secrets."caddy-env".path;

        virtualHosts = {
          "${lokiCfg.webDomain}" = {
            useACMEHost = lokiCfg.webDomain;

            extraConfig = ''
              route {
                # No auth for readiness
                handle /ready* {
                  reverse_proxy http://${lokiCfg.listenAddress}:${toString lokiCfg.listenPort}
                }

                # Everything else requires basic auth
                handle {
                  basicauth {
                    # username is whatever you want; password is a bcrypt hash in SOPS
                    qxjKhLQhXXXRsYWO {$LOKI_BCRYPT}
                  }
                  reverse_proxy http://${lokiCfg.listenAddress}:${toString lokiCfg.listenPort}
                }
              }
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && lokiCfg.enable) {
      acme.certs."${lokiCfg.webDomain}".domain = "${lokiCfg.webDomain}";
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
              ${pkgs.coreutils}/bin/install -d -m 0700 -o loki -g loki ${lokiDataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${lokiDataDir} 0700 loki loki -"
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
