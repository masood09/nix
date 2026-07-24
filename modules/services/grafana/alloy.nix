# Grafana sub-module — Alloy self-scrape of Grafana's own /metrics. Surfaces the
# dashboard/alerting front-end's health: HTTP request rates and latency, active
# alerting rules/notifications, datasource proxy errors, and DB query timing.
#
# Note on enforce_domain: Grafana sets server.enforce_domain = true (see
# default.nix), which 301-redirects HEAD /metrics to the canonical domain on a
# Host mismatch. GET /metrics is exempt and returns 200 for any Host, and
# prometheus.scrape uses GET — so a plain loopback scrape works without a Host
# override (verified against a live Grafana host).
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  grafanaEnabled = config.homelab.services.grafana.enable;

  grafanaPort = toString config.services.grafana.settings.server.http_port;
in {
  config = {
    environment.etc."alloy/grafana.alloy" = lib.mkIf (grafanaEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "grafana_self" {
          targets = [
            {
              __address__ = "127.0.0.1:${grafanaPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
