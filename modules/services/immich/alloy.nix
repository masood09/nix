# Immich sub-module — Alloy scrape of Immich's OpenTelemetry Prometheus metrics.
# Two endpoints on the immich-server process: the API server (request rates,
# response times) and the microservices/job runners (queue depth, job durations,
# image/video processing). Telemetry is enabled and the ports pinned in
# default.nix (8081 API, 8082 microservices — see docs/service-registry.org). A
# `component` label distinguishes the two on otherwise-identical metric names.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  immichCfg = config.homelab.services.immich;
in {
  config = {
    environment.etc."alloy/immich.alloy" = lib.mkIf (immichCfg.enable && alloyEnabled) {
      text = ''
        prometheus.scrape "immich_target" {
          targets = [
            {
              __address__ = "127.0.0.1:8081",
              instance    = sys.env("ALLOY_HOSTNAME"),
              component   = "api",
            },
            {
              __address__ = "127.0.0.1:8082",
              instance    = sys.env("ALLOY_HOSTNAME"),
              component   = "microservices",
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
