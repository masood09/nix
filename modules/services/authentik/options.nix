# Options — Authentik SSO (domain, ports, worker, ZFS).
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        authentik = {
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

          ldapOutpost = {
            enable = lib.mkEnableOption ''
              the native LDAP outpost (authentik-nix's services.authentik-ldap — a real
              Go binary from authentik-nix's own build, not a container). Authentik's
              embedded outpost only serves the proxy provider type; LDAP providers need
              this dedicated outpost to actually listen on the wire.
            '';
          };
        };
      };
    };
  };
}
