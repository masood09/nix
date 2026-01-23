{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  alloyEnabled = homelabCfg.services.alloy.enable;

  headscaleEnabled = homelabCfg.services.headscale.enable;
  headscaleExporterPort = toString homelabCfg.services.headscale.metricsPort;
in {
  config = {
    environment.etc."alloy/config-headscale.alloy" = lib.mkIf (headscaleEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "headscale_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${headscaleExporterPort}",
              instance = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
