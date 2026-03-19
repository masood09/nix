# Options — Authentik SSO (domain, ports, worker, ZFS).
{
  config,
  lib,
  ...
}: {
  options.homelab.services.authentik = {
    enable = lib.mkEnableOption "Whether to enable Authentik.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "auth.${config.networking.domain}";
      description = "Domain name for the Authentik web interface.";
    };

    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 9300;
      description = "Port for Authentik metrics exporter.";
    };
  };
}
