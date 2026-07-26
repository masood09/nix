# Host Info — rebuilt from Nix attrsets instead of vendored upstream JSON,
# one section at a time. Derived from the "Node Exporter Full" community
# dashboard (https://grafana.com/grafana/dashboards/1860), rev 45
# (https://grafana.com/api/dashboards/1860/revisions/45/download) — see
# node-exporter-full.json for the community dashboard this eventually
# replaces once complete.
#
# Simplified from upstream:
# - Fixed "prometheus" datasource (matching every other dashboard here)
#   instead of upstream's swappable $ds_prometheus variable — this Grafana
#   instance never has more than one Prometheus.
# - One $node variable (instance) instead of upstream's $job -> $nodename ->
#   $node cascade — this fleet only ever has one job (integrations/unix), so
#   the cascade is unused complexity.
# - Thresholds recoloured to green/orange/red (named colors, not upstream's
#   raw rgba() values) for visual consistency with Storage & Hardware.
#   Deliberately real colors, not Fleet Overview's transparent-baseline
#   scheme: "transparent" renders oddly on gauge-type panels (a rendering
#   quirk, not a config bug — verified the deployed JSON threshold steps
#   were structurally correct), and gauges are a different visual language
#   from Fleet Overview's flat status tiles anyway — a colored dial per host
#   is the normal, expected look, matching upstream's own convention.
{
  lib,
  helpers,
}: let
  inherit (helpers) mkStat mkGauge mkBarGauge mkDashboard mkQueryVar;

  nodeFilter = "instance=\"$node\"";
in
  mkDashboard {
    uid = "host-info";
    title = "Host Info";
    variables = [
      (mkQueryVar {
        name = "node";
        label = "Instance";
        query = "label_values(node_uname_info, instance)";
      })
    ];
    panels =
      [
        (mkBarGauge {
          x = 0;
          y = 1;
          w = 3;
          h = 4;
          title = "Pressure";
          description = "Resource pressure via PSI";
          unit = "percentunit";
          decimals = 1;
          min = 0;
          max = 1;
          thresholds = [
            {
              value = null;
              color = "green";
            }
            {
              value = 0.7;
              color = "orange";
            }
            {
              value = 0.9;
              color = "red";
            }
          ];
          targets = [
            {
              expr = "rate(node_pressure_cpu_waiting_seconds_total{${nodeFilter}}[$__range])";
              legend = "CPU";
            }
            {
              expr = "rate(node_pressure_memory_waiting_seconds_total{${nodeFilter}}[$__range])";
              legend = "Mem";
            }
            {
              expr = "rate(node_pressure_io_waiting_seconds_total{${nodeFilter}}[$__range])";
              legend = "I/O";
            }
            {
              expr = "rate(node_pressure_irq_stalled_seconds_total{${nodeFilter}}[$__range])";
              legend = "Irq";
            }
          ];
        })
        (mkGauge {
          x = 3;
          y = 1;
          title = "CPU Busy";
          # $__range (the actual selected time range, e.g. "30m") instead of
          # $__rate_interval — the latter is meant for graph panels and is
          # derived from panel pixel-width/datapoint density, so on a single
          # "instant" query it collapses toward the scrape-interval floor
          # (measured ~1m15s for a 30m selection here) regardless of the
          # picked range — showing a near-instantaneous spike, not a
          # meaningful average over what's actually selected. $__range fixes
          # that: it's always exactly the selected duration.
          description = "Overall CPU busy percentage (averaged across all cores), over the selected time range.";
          expr = "100 * (1 - avg(rate(node_cpu_seconds_total{mode=\"idle\", ${nodeFilter}}[$__range])))";
          decimals = 1;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                value = null;
                color = "green";
              }
              {
                value = 85;
                color = "orange";
              }
              {
                value = 95;
                color = "red";
              }
            ];
          };
        })
        (mkGauge {
          x = 6;
          y = 1;
          title = "Sys Load";
          description = "1-minute load average as a % of core count (100% = load matches core count) — same normalization as Fleet Overview's System load % panel.";
          expr = "scalar(node_load1{${nodeFilter}}) * 100 / count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu))";
          decimals = 1;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                value = null;
                color = "green";
              }
              {
                value = 85;
                color = "orange";
              }
              {
                value = 95;
                color = "red";
              }
            ];
          };
        })
        (mkGauge {
          x = 9;
          y = 1;
          title = "RAM Used";
          description = "Memory used per the kernel's reclaim-aware MemAvailable estimate — matches Fleet Overview's MemAvailable-based Memory used % panel, not the htop-view one (this doesn't exclude ZFS ARC).";
          expr = "clamp_min((1 - (node_memory_MemAvailable_bytes{${nodeFilter}} / node_memory_MemTotal_bytes{${nodeFilter}})) * 100, 0)";
          decimals = 1;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                value = null;
                color = "green";
              }
              {
                value = 80;
                color = "orange";
              }
              {
                value = 90;
                color = "red";
              }
            ];
          };
        })
        (mkGauge {
          x = 12;
          y = 1;
          title = "SWAP Used";
          description = "Percentage of configured swap space currently in use.";
          expr = "(node_memory_SwapTotal_bytes{${nodeFilter}} > bool 0) * ((node_memory_SwapTotal_bytes{${nodeFilter}} - node_memory_SwapFree_bytes{${nodeFilter}}) / (node_memory_SwapTotal_bytes{${nodeFilter}})) * 100";
          decimals = 1;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                value = null;
                color = "green";
              }
              {
                value = 10;
                color = "orange";
              }
              {
                value = 25;
                color = "red";
              }
            ];
          };
        })
        (mkGauge {
          x = 15;
          y = 1;
          title = "Root FS Used";
          description = "Percentage of the root filesystem's space currently used.";
          expr = ''
            (
              (node_filesystem_size_bytes{${nodeFilter}, mountpoint="/", fstype!="rootfs"}
               - node_filesystem_avail_bytes{${nodeFilter}, mountpoint="/", fstype!="rootfs"})
              / node_filesystem_size_bytes{${nodeFilter}, mountpoint="/", fstype!="rootfs"}
            ) * 100
          '';
          decimals = 1;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                value = null;
                color = "green";
              }
              {
                value = 80;
                color = "orange";
              }
              {
                value = 90;
                color = "red";
              }
            ];
          };
        })
        (mkStat {
          x = 18;
          y = 1;
          w = 2;
          h = 2;
          title = "CPU Cores";
          expr = "count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu))";
          unit = "short";
        })
        (mkStat {
          x = 20;
          y = 1;
          w = 2;
          h = 2;
          title = "RAM Total";
          expr = "node_memory_MemTotal_bytes{${nodeFilter}}";
          unit = "bytes";
          decimals = 0;
        })
        (mkStat {
          x = 22;
          y = 1;
          w = 2;
          h = 2;
          title = "SWAP Total";
          expr = "node_memory_SwapTotal_bytes{${nodeFilter}}";
          unit = "bytes";
          decimals = 0;
        })
        (mkStat {
          x = 18;
          y = 3;
          w = 2;
          h = 2;
          title = "RootFS Total";
          expr = "node_filesystem_size_bytes{${nodeFilter}, mountpoint=\"/\", fstype!=\"rootfs\"}";
          unit = "bytes";
          decimals = 0;
        })
        (mkStat {
          x = 20;
          y = 3;
          w = 4;
          h = 2;
          title = "Uptime";
          expr = "node_time_seconds{${nodeFilter}} - node_boot_time_seconds{${nodeFilter}}";
          unit = "s";
        })
      ]
      # Row header — Grafana requires it as its own top-level panel; id gets
      # reassigned by mkDashboard along with everything else.
      ++ [
        {
          type = "row";
          title = "Quick CPU / Mem / Disk";
          collapsed = false;
          gridPos = {
            x = 0;
            y = 0;
            w = 24;
            h = 1;
          };
          panels = [];
        }
      ];
  }
