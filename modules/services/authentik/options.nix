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

          forwardAuthHosts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["sabnzbd.mantannest.com"];
            description = ''
              External hostnames — in addition to webDomain — that front a Proxy Provider
              app served by Authentik's embedded outpost (see infra-tofu's
              modules/authentik/proxy.tf). The embedded outpost shares authentik-server's
              own listener and dispatches by Host header internally, but Caddy still picks
              the site block by Host header *before* that — a request for
              sabnzbd.mantannest.com with no matching Caddy vhost here never reaches
              authentik at all; Caddy just returns an empty 200 fallback. Every app domain
              onboarded onto forward-auth/proxy-mode SSO must be listed here.
            '';
          };
        };
      };
    };
  };
}
