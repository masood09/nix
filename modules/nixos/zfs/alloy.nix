# ZFS Alloy config — generates an Alloy scrape config fragment for the
# ZFS Prometheus exporter so metrics flow to the central Prometheus.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  alloyEnabled = homelabCfg.services.alloy.enable;

  anyManagedDatasets = (lib.attrNames (lib.filterAttrs (_: v: v.enable or false) homelabCfg.zfs.datasets)) != [];

  enableZFS = (homelabCfg.isRootZFS or false) || anyManagedDatasets;
  zfsExporterPort = toString config.services.prometheus.exporters.zfs.port;
in {
  config = {
    environment.etc."alloy/zfs.alloy" = lib.mkIf (enableZFS && alloyEnabled && config.services.prometheus.exporters.zfs.enable) {
      text = ''
        prometheus.scrape "zfs_target" {
          targets = [
            {
              __address__ = "127.0.0.1:${zfsExporterPort}",
              instance = sys.env("ALLOY_HOSTNAME"),
            },
          ]

          forward_to = [prometheus.remote_write.metrics_service.receiver]
        }
      '';
    };
  };
}
