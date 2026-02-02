{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  garageCfg = homelabCfg.services.garage;

  caddyEnabled = config.services.caddy.enable;

  # Helpers
  mkAddr = addr: port: "${addr}:${toString port}";
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf garageCfg.enable {
    homelab.zfs.datasets = lib.mkMerge [
      (lib.mkIf garageCfg.zfs.enable {
        garage-data = {
          enable = true;
          dataset = garageCfg.zfs.datasetData;
          properties = garageCfg.zfs.propertiesData;
          mountpoint = garageCfg.dataDir;
          requiredBy = ["garage.service"];
          restic.enable = false;
        };

        garage-meta = {
          enable = true;
          dataset = garageCfg.zfs.datasetMeta;
          properties = garageCfg.zfs.propertiesMeta;
          mountpoint = garageCfg.metaDir;
          requiredBy = ["garage.service"];
          restic.enable = true;
        };
      })
    ];

    services = {
      garage = {
        enable = true;

        package = pkgs.garage_2;
        environmentFile = config.sops.secrets."garage.env".path;

        inherit (garageCfg) logLevel;

        settings = {
          data_dir = toString garageCfg.dataDir;
          metadata_dir = toString garageCfg.metaDir;
          db_engine = garageCfg.dbEngine;

          replication_factor = garageCfg.replicationFactor;

          rpc_bind_addr = mkAddr garageCfg.rpc.listenAddress garageCfg.rpc.port;
          rpc_public_addr = garageCfg.rpc.publicAddress;

          s3_api = {
            s3_region = garageCfg.s3.region;
            api_bind_addr = mkAddr garageCfg.s3.listenAddress garageCfg.s3.port;
          };

          admin = {
            api_bind_addr = mkAddr garageCfg.admin.listenAddress garageCfg.admin.port;
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${garageCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              route {
                handle /-/health {
                  rewrite * /health
                  reverse_proxy http://127.0.0.1:${toString garageCfg.admin.port}
                }

                handle {
                  reverse_proxy http://127.0.0.1:${toString garageCfg.s3.port}
                }
              }
            '';
          };
        };
      };
    };

    users = {
      users = {
        garage = {
          isSystemUser = true;
          group = "garage";
          uid = garageCfg.userId;
        };
      };

      groups = {
        garage = {
          gid = garageCfg.groupId;
        };
      };
    };

    systemd = {
      # Service ordering + mount requirements
      services = {
        garage = lib.mkMerge [
          {
            unitConfig = {
              RequiresMountsFor = [
                (toString garageCfg.dataDir)
                (toString garageCfg.metaDir)
              ];
            };

            serviceConfig = {
              DynamicUser = lib.mkForce false;

              # stop systemd from trying to manage /var/lib/private + bind-mount behavior
              StateDirectory = lib.mkForce null;

              User = "garage";
              Group = "garage";

              # with ProtectSystem=strict, you must explicitly allow writes here
              ReadWritePaths = [
                garageCfg.dataDir
                garageCfg.metaDir
              ];
            };
          }
          (lib.mkIf garageCfg.zfs.enable {
            requires = [
              "zfs-dataset-garage-data.service"
              "zfs-dataset-garage-meta.service"
            ];

            after = [
              "zfs-dataset-garage-data.service"
              "zfs-dataset-garage-meta.service"
            ];
          })
        ];

        garage-permissions = {
          description = "Fix Garage dataDir and metaDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["garage.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals garageCfg.zfs.enable [
              "zfs-dataset-garage-data.service"
              "zfs-dataset-garage-meta.service"
            ];
          requires = lib.optionals garageCfg.zfs.enable [
            "zfs-dataset-garage-data.service"
            "zfs-dataset-garage-meta.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown -R garage:garage ${toString garageCfg.dataDir}
              ${pkgs.coreutils}/bin/chown -R garage:garage ${toString garageCfg.metaDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        "d ${toString garageCfg.dataDir} 0700 garage garage -"
        "z ${toString garageCfg.dataDir} 0700 garage garage -"
        "d ${toString garageCfg.metaDir} 0700 garage garage -"
        "z ${toString garageCfg.metaDir} 0700 garage garage -"
      ];
    };

    # Impermanence fallback if you ever disable ZFS datasets
    environment = lib.mkIf (homelabCfg.impermanence && !garageCfg.zfs.enable) {
      persistence."/nix/persist".directories = [
        garageCfg.dataDir
        garageCfg.metaDir
      ];
    };
  };
}
