{
  config,
  lib,
  ...
}: {
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

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "s3.${config.networking.domain}";
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
}
