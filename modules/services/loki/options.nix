# Options — Loki log aggregation (domain, port, retention periods, ZFS).
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        loki = {
          enable = lib.mkEnableOption "Whether to enable Loki.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "loki.${config.networking.domain}";
            description = "Domain name for the Loki web interface.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/loki/";
            description = "Directory for Loki data storage.";
          };

          listenAddress = lib.mkOption {
            default = "127.0.0.1";
            type = lib.types.str;
            description = "Address Loki listens on for HTTP requests.";
          };

          listenPort = lib.mkOption {
            default = 3100;
            type = lib.types.port;
            description = "Port Loki listens on for HTTP requests.";
          };

          userId = lib.mkOption {
            default = 3005;
            type = lib.types.ints.u16;
            description = "UID for the Loki service user.";
          };

          groupId = lib.mkOption {
            default = 3005;
            type = lib.types.ints.u16;
            description = "GID for the Loki service group.";
          };

          retentionPeriod = {
            default = lib.mkOption {
              type = lib.types.str;
              default = "240h"; # 10d
              description = "Default log retention period for streams without a specific level.";
            };

            debug = lib.mkOption {
              type = lib.types.str;
              default = "24h"; # 1d
              description = "Retention period for debug-level log streams.";
            };

            info = lib.mkOption {
              type = lib.types.str;
              inherit (config.homelab.services.loki.retentionPeriod) default;
              description = "Retention period for info-level log streams.";
            };

            warn = lib.mkOption {
              type = lib.types.str;
              default = "720h"; # 30d
              description = "Retention period for warn-level log streams.";
            };

            error = lib.mkOption {
              type = lib.types.str;
              default = "1440h"; # 60d
              description = "Retention period for error-level log streams.";
            };
          };

          zfs = zfsOpts {
            serviceName = "Loki";
            dataset = "dpool/tank/services/loki";
            properties = {
              logbias = "latency";
              recordsize = "16K";
              relatime = "off";
              primarycache = "metadata";
            };
          };
        };
      };
    };
  };
}
