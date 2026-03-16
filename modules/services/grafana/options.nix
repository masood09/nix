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
      description = "Domain name for the Grafana web interface.";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/grafana/";
      description = "Directory for Grafana persistent data.";
    };

    oauth = {
      providerHost = lib.mkOption {
        type = lib.types.str;
        default = "auth.${config.networking.domain}";
        description = "Hostname of the OAuth/OIDC provider.";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "grafana";
        description = "OAuth client ID for Grafana.";
      };

      scopes = lib.mkOption {
        type = lib.types.str;
        default = "openid email profile";
        description = "OAuth scopes to request from the provider.";
      };

      roleAttributePath = lib.mkOption {
        type = lib.types.str;
        default = "contains(groups, 'homelab-admins') && 'Admin' || 'Viewer'";
        description = "JMESPath expression to map OAuth claims to Grafana roles.";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Grafana dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/grafana";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "all";
        };
        description = "ZFS properties to apply to the dataset.";
      };
    };
  };
}
