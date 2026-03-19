# Options — MongoDB document database (data dir, ZFS).
{lib, ...}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        mongodb = {
          enable = lib.mkEnableOption "Whether to enable MongoDB.";

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/mongodb";
            description = "Directory for MongoDB data storage.";
          };

          userId = lib.mkOption {
            default = 3012;
            type = lib.types.ints.u16;
            description = "UID for the MongoDB service user.";
          };

          groupId = lib.mkOption {
            default = 3012;
            type = lib.types.ints.u16;
            description = "GID for the MongoDB service group.";
          };

          zfs = zfsOpts {
            serviceName = "MongoDB";
            dataset = "fpool/fast/services/mongodb";
            properties = {
              atime = "off";
              compression = "zstd";
              logbias = "latency";
              recordsize = "16K";
              redundant_metadata = "most";
              primarycache = "all";
              xattr = "sa";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
