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
  options.homelab.services.jobscraper = {
    enable = lib.mkEnableOption "Whether to enable Job Scraper.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "jobscraper.mantannest.com";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 8902;
      type = lib.types.port;
    };
  };

  config = lib.mkIf (jobscraperCfg.enable && podmanEnabled) {
    virtualisation.oci-containers.containers.jobscraper = {
      # renovate: datasource=docker depName=masood09/jobscraper
      image = "masood09/jobscraper:0.1.1";
      autoStart = true;

      environmentFiles = [
        config.sops.secrets."jobscraper-env".path
      ];

      ports = [
        "${jobscraperCfg.listenAddress}:${toString jobscraperCfg.listenPort}:8080"
      ];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${jobscraperCfg.webDomain}" = {
            useACMEHost = jobscraperCfg.webDomain;
            extraConfig = ''
              reverse_proxy http://${jobscraperCfg.listenAddress}:${toString jobscraperCfg.listenPort}
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && jobscraperCfg.enable) {
      acme.certs."${jobscraperCfg.webDomain}".domain = "${jobscraperCfg.webDomain}";
    };
  };
}
