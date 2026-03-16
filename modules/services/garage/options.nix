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
      description = "Log verbosity level for Garage.";
    };

    replicationFactor = lib.mkOption {
      type = lib.types.int;
      default = 1;
      description = "Number of copies of each data block to store across the cluster.";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "s3.${config.networking.domain}";
      description = "Public S3 API hostname (for reverse proxy / TLS).";
    };

    metaDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/garage_meta";
      description = "Directory for Garage metadata storage.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/garage_data";
      description = "Directory for Garage object data storage.";
    };

    userId = lib.mkOption {
      default = 3006;
      type = lib.types.ints.u16;
      description = "UID for the Garage service user.";
    };

    groupId = lib.mkOption {
      default = 3006;
      type = lib.types.ints.u16;
      description = "GID for the Garage service group.";
    };

    rpc = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address for the Garage RPC server to bind to.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3901;
        description = "Port for the Garage RPC server.";
      };

      publicAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:3901";
        description = "Public address advertised to other Garage nodes.";
      };
    };

    s3 = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address for the S3 API server to bind to.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 3900;
        description = "Port for the S3 API server.";
      };

      region = lib.mkOption {
        type = lib.types.str;
        default = "homelab";
        description = "S3 region name for this Garage cluster.";
      };
    };

    admin = {
      listenAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address for the Garage admin API to bind to.";
      };
      port = lib.mkOption {
        type = lib.types.port;
        default = 3903;
        description = "Port for the Garage admin API.";
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
        description = "ZFS dataset for Garage metadata storage.";
      };

      datasetData = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/garage_data";
        description = "ZFS dataset for Garage object data storage.";
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
