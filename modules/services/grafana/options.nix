{
  config,
  lib,
  ...
}: {
  options.homelab.services.grafana = {
    enable = lib.mkEnableOption "Whether to enable Grafana.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "grafana.${config.networking.domain}";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/grafana/";
    };

    oauth = {
      providerHost = lib.mkOption {
        type = lib.types.str;
        default = "auth.${config.networking.domain}";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "grafana";
      };

      scopes = lib.mkOption {
        type = lib.types.str;
        default = "openid email profile";
      };

      roleAttributePath = lib.mkOption {
        type = lib.types.str;
        default = "contains(groups, 'homelab-admins') && 'Admin' || 'Viewer'";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Grafana dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/grafana";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "all";
        };
      };
    };
  };
}
