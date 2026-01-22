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
  options.homelab.services.garage = {
    enable = lib.mkEnableOption "Whether to enable Garage S3 (GarageHQ).";

    logLevel = lib.mkOption {
      type = lib.types.str;
      default = "info";
    };

    replicationFactor = lib.mkOption {
      type = lib.types.int;
      default = 1;
    };

    s3Domain = lib.mkOption {
      type = lib.types.str;
      default = "s3.mantannest.com";
      description = "Public S3 API hostname (for reverse proxy / TLS).";
    };

    metaDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/garage_meta";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/garage_data";
    };

    userId = lib.mkOption {
      default = 3006;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3006;
      type = lib.types.ints.u16;
    };

    rpc = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3901;
      };

      publicAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:3901";
      };
    };

    s3 = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3900;
      };

      region = lib.mkOption {
        type = lib.types.str;
        default = "homelab";
      };
    };

    admin = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3903;
      };
    };

    # Core garage config
    dbEngine = lib.mkOption {
      type = lib.types.str;
      default = "sqlite";
      description = "Garage db engine (e.g. sqlite, lmdb).";
    };

    zfs = {
      enable = lib.mkEnableOption "Create ZFS datasets for Garage data/meta.";

      datasetMeta = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/garage_meta";
      };

      datasetData = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/garage_data";
      };

      propertiesMeta = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          recordsize = "16K";
          logbias = "latency";
        };
        description = "ZFS properties for metadata dataset (small random IO).";
      };

      propertiesData = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          recordsize = "1M";
          logbias = "throughput";
        };
        description = "ZFS properties for data dataset (large objects).";
      };
    };
  };

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
        environmentFile = config.sops.secrets."garage-env".path;

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
          "${garageCfg.s3Domain}" = {
            useACMEHost = garageCfg.s3Domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString garageCfg.s3.port}
            '';
          };
        };
      };
    };

    security.acme = lib.mkIf caddyEnabled {
      certs."${garageCfg.s3Domain}".domain = garageCfg.s3Domain;
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
              ${pkgs.coreutils}/bin/install -d -m 0700 -o garage -g garage ${toString garageCfg.dataDir}
              ${pkgs.coreutils}/bin/install -d -m 0700 -o garage -g garage ${toString garageCfg.metaDir}
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
