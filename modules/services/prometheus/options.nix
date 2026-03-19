# Options — Prometheus metrics (port, retention, scrape targets, ZFS).
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
        prometheus = {
          enable = lib.mkEnableOption "Whether to enable Prometheus.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "prometheus.${config.networking.domain}";
            description = "Domain name for the Prometheus web interface.";
          };

          retentionTime = lib.mkOption {
            type = lib.types.str;
            default = "30d";
            description = "How long to retain metrics data.";
          };

          zfs = zfsOpts {
            serviceName = "Prometheus";
            dataset = "dpool/tank/services/prometheus";
            properties = {
              logbias = "throughput";
              recordsize = "16K";
              redundant_metadata = "most";
              primarycache = "all";
            };
          };
        };
      };
    };
  };
}
