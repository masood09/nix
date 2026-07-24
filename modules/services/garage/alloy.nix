# Garage sub-module — Alloy scrape of the S3 object store's admin API metrics.
# Garage serves Prometheus metrics at /metrics on its admin API port (no token
# required for that endpoint here). Surfaces S3 request rates/latency, block
# and object counts, RPC health, and data/metadata store activity.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  garageCfg = config.homelab.services.garage;

  garageAdminPort = toString garageCfg.admin.port;
in {
  config = {
    environment.etc."alloy/garage.alloy" = lib.mkIf (garageCfg.enable && alloyEnabled) {
      text = ''
        prometheus.scrape "garage_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${garageAdminPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
