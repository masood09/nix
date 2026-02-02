{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  jobscraperCfg = homelabCfg.services.jobscraper;
  podmanEnabled = homelabCfg.services.podman.enable;
  caddyEnabled = config.services.caddy.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf (jobscraperCfg.enable && podmanEnabled) {
    virtualisation.oci-containers.containers.jobscraper = {
      # renovate: datasource=docker depName=masood09/jobscraper
      image = "masood09/jobscraper:0.1.3";
      autoStart = true;

      environmentFiles = [
        config.sops.secrets."jobscraper.env".path
      ];

      ports = [
        "${jobscraperCfg.listenAddress}:${toString jobscraperCfg.listenPort}:8080"
      ];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${jobscraperCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://${jobscraperCfg.listenAddress}:${toString jobscraperCfg.listenPort}
            '';
          };
        };
      };
    };
  };
}
