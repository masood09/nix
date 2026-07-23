# Prometheus sub-module — Alloy self-scrape of the Prometheus server's own
# /metrics. Makes the metrics store observable in itself: remote-write receiver
# health, TSDB head series/chunks, ingestion errors, and rule evaluation.
# Scraped on the loopback port directly, bypassing the Caddy basic-auth front.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  prometheusEnabled = config.services.prometheus.enable;

  prometheusPort = toString config.services.prometheus.port;
in {
  config = {
    environment.etc."alloy/prometheus.alloy" = lib.mkIf (prometheusEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "prometheus_self" {
          targets = [
            {
              __address__ = "127.0.0.1:${prometheusPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
