{
  lib,
  pkgs,
  ...
}: {
  options.homelab.services.postgresql = {
    enable = lib.mkEnableOption "Whether to enable PostgreSQL database.";
    package = lib.mkPackageOption pkgs "postgresql_17" {};
    enableTCPIP = lib.mkEnableOption "Whether PostgreSQL should listen on all network interfaces.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/postgresql/17";
    };

    backup = {
      enable = lib.mkEnableOption "Whether to enable Postgresql backup.";

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/backup/postgresql";
      };

      zfs = {
        enable = lib.mkEnableOption "Store backup dataDir on a ZFS dataset.";

        restic = {
          enable = lib.mkEnableOption "Enable restic backup";
        };

        dataset = lib.mkOption {
          type = lib.types.str;
          default = "fpool/fast/backup/postgresql";
          description = "ZFS dataset to create and mount at dataDir.";
        };

        properties = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {
            recordsize = "1M";
          };
          description = "ZFS properties for the dataset.";
        };
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Postgresql dataDir on a ZFS dataset.";

      restic = {
        enable = lib.mkEnableOption "Enable restic backup";
      };

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "fpool/fast/services/postgresql_17";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          compression = "lz4";
          logbias = "latency";
          recordsize = "8K";
          redundant_metadata = "most";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };
}
