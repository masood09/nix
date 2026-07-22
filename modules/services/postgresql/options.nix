# Options — PostgreSQL database (package, data dir, backup, ZFS).
{
  lib,
  pkgs,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        postgresql = {
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

          collationCheck = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = ''
                Periodically compare each database's recorded collation version
                against the one the OS now provides, and log at error priority
                when they drift.

                A glibc upgrade can change collation ordering, which silently
                invalidates text indexes until they are rebuilt. Only services
                that surface PostgreSQL notices in their own logs (authentik)
                complain about this on their own; everything else stays quiet.
              '';
            };

            startAt = lib.mkOption {
              type = lib.types.str;
              default = "weekly";
              description = "systemd calendar expression for the collation drift check.";
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
      };
    };
  };
}
