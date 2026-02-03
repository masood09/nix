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
              reverse_proxy http://127.0.0.1:${toString cfg.port}
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
