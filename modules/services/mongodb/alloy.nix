# MongoDB sub-module — Alloy scrape of the mongodb_exporter. Surfaces server
# status (connections, opcounters, memory, network), replication/oplog state,
# and per-database/collection stats for the MongoDB that backs Nightscout.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  mongodbEnabled = config.homelab.services.mongodb.enable;

  mongodbExporterPort = toString config.services.prometheus.exporters.mongodb.port;
in {
  config = {
    environment.etc."alloy/mongodb.alloy" = lib.mkIf (mongodbEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "mongodb_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${mongodbExporterPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
