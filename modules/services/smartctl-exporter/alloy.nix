# smartctl exporter sub-module — Alloy scrape of the disk SMART exporter, so
# per-disk health flows to the central Prometheus alongside the ZFS pool metrics.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  smartctlEnabled = config.homelab.services.smartctl-exporter.enable;

  smartctlPort = toString config.services.prometheus.exporters.smartctl.port;
in {
  config = {
    environment.etc."alloy/smartctl.alloy" = lib.mkIf (smartctlEnabled && alloyEnabled) {
      text = ''
        prometheus.scrape "smartctl_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${smartctlPort}",
              instance    = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
