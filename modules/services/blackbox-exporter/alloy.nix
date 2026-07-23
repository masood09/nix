# blackbox exporter sub-module — Alloy scrape using the multi-target relabel
# pattern: one scrape job fans out over a target list, rewriting each entry so
# the probed URL/host is passed to the exporter as ?target=… while __address__
# points at the local exporter. The probed target becomes the `instance` label,
# so every endpoint is its own series in the central Prometheus.
{
  config,
  lib,
  ...
}: let
  alloyEnabled = config.homelab.services.alloy.enable;
  cfg = config.homelab.services.blackbox-exporter;

  bbAddr = "127.0.0.1:${toString config.services.prometheus.exporters.blackbox.port}";

  # Each element carries a trailing comma (River requires it after the final
  # element of a multiline list), so items are newline-separated, not comma-joined.
  mkTargets = addrs: lib.concatMapStringsSep "\n        " (a: ''{ __address__ = "${a}" },'') addrs;

  mkScrapeBlock = name: module: addrs: ''
    discovery.relabel "blackbox_${name}" {
      targets = [
        ${mkTargets addrs}
      ]

      rule {
        source_labels = ["__address__"]
        target_label  = "__param_target"
      }
      rule {
        source_labels = ["__param_target"]
        target_label  = "instance"
      }
      rule {
        target_label = "__address__"
        replacement  = "${bbAddr}"
      }
    }

    prometheus.scrape "blackbox_${name}" {
      targets         = discovery.relabel.blackbox_${name}.output
      forward_to      = [prometheus.remote_write.metrics_service.receiver]
      metrics_path    = "/probe"
      params          = { module = ["${module}"] }
      scrape_interval = "60s"
    }
  '';

  httpBlock = lib.optionalString (cfg.httpTargets != []) (mkScrapeBlock "http" "http_2xx" cfg.httpTargets);
  dnsBlock = lib.optionalString (cfg.dnsTargets != []) (mkScrapeBlock "dns" "dns_a" cfg.dnsTargets);
in {
  config = {
    environment.etc."alloy/blackbox.alloy" = lib.mkIf (cfg.enable && alloyEnabled) {
      text = ''
        ${httpBlock}
        ${dnsBlock}
      '';
    };
  };
}
