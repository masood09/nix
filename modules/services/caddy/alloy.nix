# Caddy sub-module — Alloy metrics scraping for the reverse proxy that fronts
# every service. Caddy exposes Prometheus metrics on its admin API endpoint
# (127.0.0.1:2019/metrics) once the `metrics` global option is enabled (see
# default.nix). This gives per-vhost request rate, status classes, and request
# duration (per_host labelling), plus caddy_* series covering TLS/ACME
# certificate management — the request/edge layer that node_exporter can't see.
# Port 2019 is Caddy's upstream-default admin listener (see
# docs/service-registry.org).
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  caddyEnabled = config.homelab.services.caddy.enable;
in {
  config = {
    environment.etc."alloy/caddy.alloy" = lib.mkIf (caddyEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "caddy_target" {
          targets = [
            {
              __address__ = "127.0.0.1:2019",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
