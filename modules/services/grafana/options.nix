# Options — Grafana dashboards (domain, port, ZFS, OAuth).
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
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

    zfs = zfsOpts {
      serviceName = "Grafana";
      dataset = "dpool/tank/services/grafana";
      properties = {
        logbias = "latency";
        recordsize = "16K";
        relatime = "off";
        primarycache = "all";
      };
    };
  };
}
