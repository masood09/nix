{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  alloyEnabled = homelabCfg.services.alloy.enable;

  enableAuthentik = homelabCfg.services.authentik.enable;
  authentikExporterPort = "9300";
in {
  config = {
    environment.etc."alloy/config-authentik.alloy" = lib.mkIf (enableAuthentik && alloyEnabled) {
      text = ''
        prometheus.scrape "authentik_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${authentikExporterPort}",
              instance = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
