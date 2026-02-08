{
  config,
  lib,
  ...
}: let
  zfsDatasetOpts = lib.types.submodule (_: {
    options = {
      dataset = lib.mkOption {
        type = lib.types.str;
        description = "ZFS dataset name.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = "ZFS properties to apply to the dataset.";
      };
    };
  });
in {
  options.homelab.services.matrix-synapse = {
    enable = lib.mkEnableOption "Whether to enable Matrix Synapse.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/matrix-synapse";
    };

    mediaDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/matrix-synapse-media";
    };

    serverName = lib.mkOption {
      type = lib.types.str;
      default = config.networking.domain;
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "https://matrix.${config.networking.domain}/";
    };

    listenAddress = lib.mkOption {
      default = ["127.0.0.1"];
      type = lib.types.listOf lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 8008;
      type = lib.types.port;
    };

    zfs = {
      enable = lib.mkEnableOption "Store Matrix Synapse data on ZFS dataset.";

      dataDir = lib.mkOption {
        type = zfsDatasetOpts;
        default = {
          dataset = "fpool/fast/services/matrix-synapse";
          properties = {
            atime = "off";
            compression = "zstd";
            recordsize = "16K";
            logbias = "latency";
            xattr = "sa";
            acltype = "posixacl";
            redundant_metadata = "most";
          };
        };
      };

      mediaDir = lib.mkOption {
        type = zfsDatasetOpts;
        default = {
          dataset = "dpool/tank/services/matrix-synapse-media";
          properties = {
            atime = "off";
            compression = "zstd";
            recordsize = "1M";
            logbias = "throughput";
            redundant_metadata = "most";
          };
        };
      };
    };
  };
}
