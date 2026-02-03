{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  alloyEnabled = homelabCfg.services.alloy.enable;

  blockyCfg = homelabCfg.services.blocky;

  blockyMetricsEnabled = blockyCfg.enable && blockyCfg.metrics.enable;
  blockyExporterPort = toString blockyCfg.metrics.listenPort;
in {
  config = {
    environment.etc."alloy/blocky.alloy" = lib.mkIf (blockyMetricsEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "blocky_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${blockyExporterPort}",
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
