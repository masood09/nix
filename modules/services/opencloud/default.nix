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
    ./options.nix
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
              reverse_proxy http://127.0.0.1:9200
            '';
          };

          "${collaboraWebDomain}" = {
            useACMEHost = collaboraWebDomain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:9980
            '';
          };

          "${wopiWebDomain}" = {
            useACMEHost = wopiWebDomain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:9300
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && cfg.enable) {
      acme.certs = {
        "${cfg.webDomain}".domain = "${cfg.webDomain}";
        "${collaboraWebDomain}".domain = "${collaboraWebDomain}";
        "${wopiWebDomain}".domain = "${wopiWebDomain}";
      };
    };
  };
}
