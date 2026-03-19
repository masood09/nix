# OpenCloud — self-hosted file sync & share (ownCloud successor).
# Runs as Podman containers with Collabora Online for document editing.
# Uses its own wildcard ACME cert for *.opencloud.domain subdomains.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.opencloud;
  podmanEnabled = homelabCfg.services.podman.enable;
  caddyEnabled = config.services.caddy.enable;

  collaboraWebDomain = "collabora.${cfg.webDomain}";
  wopiWebDomain = "wopi.${cfg.webDomain}";
in {
  imports = [
    ./containers.nix
    ./options.nix
    ./systemd.nix
    ./users.nix
    ./zfs.nix
  ];

  config = lib.mkIf (cfg.enable && podmanEnabled) {
    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = cfg.webDomain;
            extraConfig = ''
              handle /-/health {
                rewrite * /healthz
                reverse_proxy http://127.0.0.1:${toString cfg.metrics.port}
              }

              handle {
                reverse_proxy http://127.0.0.1:${toString cfg.port}
              }
            '';
          };

          "${collaboraWebDomain}" = {
            useACMEHost = cfg.webDomain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.collabora.port}
            '';
          };

          "${wopiWebDomain}" = {
            useACMEHost = cfg.webDomain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.wopi.port}
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && cfg.enable) {
      acme.certs."${cfg.webDomain}" = {
        extraDomainNames = [
          "${cfg.webDomain}"
          "*.${cfg.webDomain}"
        ];
      };
    };
  };
}
