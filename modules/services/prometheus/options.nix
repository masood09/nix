{
  config,
  lib,
  ...
}: {
  options.homelab.services.prometheus = {
    enable = lib.mkEnableOption "Whether to enable Prometheus.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "prometheus.${config.networking.domain}";
    };

    zfs = {
      enable = lib.mkEnableOption "Store Prometheus dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/prometheus";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "throughput";
          recordsize = "16K";
          redundant_metadata = "most";
          relatime = "off";
          primarycache = "all";
        };
      };
    };
  };
}
