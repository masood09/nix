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
}
