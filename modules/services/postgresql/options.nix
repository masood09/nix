{
  lib,
  pkgs,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
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

      zfs = zfsOpts {
        serviceName = "PostgreSQL backup";
        dataset = "fpool/fast/backup/postgresql";
        properties = {
          recordsize = "1M";
        };
        withRestic = true;
      };
    };

    zfs = zfsOpts {
      serviceName = "PostgreSQL";
      dataset = "fpool/fast/services/postgresql_17";
      properties = {
        compression = "lz4";
        logbias = "latency";
        primarycache = "metadata";
        recordsize = "8K";
        redundant_metadata = "most";
      };
      withRestic = true;
    };
  };
}
