# Loki sub-module — Alloy self-scrape of the Loki server's own /metrics. Surfaces
# log-ingestion health (distributor/ingester rates, append failures, discarded
# samples, retention/compaction) so a silent drop in log flow is visible in
# Prometheus rather than only as an empty Grafana panel.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  lokiCfg = config.homelab.services.loki;

  lokiPort = toString lokiCfg.listenPort;
in {
  config = {
    environment.etc."alloy/loki.alloy" = lib.mkIf (lokiCfg.enable && alloyEnabled) {
      text = ''
        prometheus.scrape "loki_self" {
          targets = [
            {
              __address__ = "127.0.0.1:${lokiPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
