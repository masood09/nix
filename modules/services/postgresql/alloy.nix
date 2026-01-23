{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  postgresqlEnabled = config.homelab.services.postgresql.enable;

  postgresqlExporterPort = toString config.services.prometheus.exporters.postgres.port;
in {
  config = {
    environment.etc."alloy/config-postgresql.alloy" = lib.mkIf (postgresqlEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "postgresql_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${postgresqlExporterPort}",
              instance = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
