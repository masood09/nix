{lib, ...}: {
  options.homelab.services.mongodb = {
    enable = lib.mkEnableOption "Whether to enable MongoDB.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/mongodb";
    };

    userId = lib.mkOption {
      default = 3012;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3012;
      type = lib.types.ints.u16;
    };

    zfs = {
      enable = lib.mkEnableOption "Store MongoDB dataDir on a ZFS dataset.";

      restic = {
        enable = lib.mkEnableOption "Enable restic backup";
      };

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/mongodb";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          atime = "off";
          compression = "zstd";
          logbias = "latency";
          recordsize = "16K";
          redundant_metadata = "most";
          primarycache = "all";
          xattr = "sa";
        };
        description = "ZFS properties optimized for MongoDB.";
      };
    };
  };
}
