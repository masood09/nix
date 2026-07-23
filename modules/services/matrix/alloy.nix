# Matrix sub-module — Alloy scrape of the Synapse homeserver metrics. Surfaces
# federation transaction rates, event send/persist timing, database txn latency,
# background process activity, and cache hit rates. Synapse serves these at
# /_synapse/metrics (not the default /metrics) on its localhost metrics listener.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  synapseCfg = config.homelab.services.matrix.synapse;

  synapseMetricsPort = toString synapseCfg.metricsPort;
in {
  config = {
    environment.etc."alloy/matrix-synapse.alloy" = lib.mkIf (synapseCfg.enable && alloyEnabled) {
      text = ''
        prometheus.scrape "matrix_synapse_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${synapseMetricsPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          metrics_path = "/_synapse/metrics"
          forward_to   = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
