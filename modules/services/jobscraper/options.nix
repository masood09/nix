# Options — Job Scraper (domain, port, OAuth).
{
  config,
  lib,
  ...
}: {
  options.homelab.services.jobscraper = {
    enable = lib.mkEnableOption "Whether to enable Job Scraper.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "jobscraper.${config.networking.domain}";
      description = "Domain name for the Job Scraper web interface.";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
      description = "Address Job Scraper listens on for HTTP requests.";
    };

    listenPort = lib.mkOption {
      default = 8902;
      type = lib.types.port;
      description = "Port Job Scraper listens on for HTTP requests.";
    };
  };
}
