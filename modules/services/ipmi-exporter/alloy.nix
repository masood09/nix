# IPMI exporter sub-module — Alloy scrape of the local BMC sensor exporter.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  ipmiEnabled = config.homelab.services.ipmi-exporter.enable;

  ipmiPort = toString config.services.prometheus.exporters.ipmi.port;
in {
  config = {
    environment.etc."alloy/ipmi.alloy" = lib.mkIf (ipmiEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "ipmi_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${ipmiPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
