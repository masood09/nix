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
  inherit (helpers) mkStat mkGauge mkBarGauge mkStackedTimeseries mkDashboard mkQueryVar;

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
        (mkStackedTimeseries {
          x = 0;
          y = 6;
          title = "CPU Basic";
          description = "CPU time spent busy vs idle, split by activity type";
          unit = "percentunit";
          min = 0;
          fillOpacity = 40;
          lineInterpolation = "smooth";
          stacking = {
            group = "A";
            mode = "percent";
          };
          legendWidth = 250;
          tooltipSort = "desc";
          overrides = [
            {
              matcher = {
                id = "byName";
                options = "Busy Iowait";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#890F02";
                    mode = "fixed";
                  };
                }
              ];
            }
            {
              matcher = {
                id = "byName";
                options = "Idle";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#052B51";
                    mode = "fixed";
                  };
                }
              ];
            }
            {
              matcher = {
                id = "byName";
                options = "Busy System";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#EAB839";
                    mode = "fixed";
                  };
                }
              ];
            }
            {
              matcher = {
                id = "byName";
                options = "Busy User";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#0A437C";
                    mode = "fixed";
                  };
                }
              ];
            }
            {
              matcher = {
                id = "byName";
                options = "Busy Other";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#6D1F62";
                    mode = "fixed";
                  };
                }
              ];
            }
          ];
          targets = [
            {
              expr = "avg(rate(node_cpu_seconds_total{${nodeFilter}, mode=\"system\"}[$__rate_interval]))";
              legend = "Busy System";
              step = 240;
            }
            {
              expr = "avg(rate(node_cpu_seconds_total{${nodeFilter}, mode=\"user\"}[$__rate_interval]))";
              legend = "Busy User";
              step = 240;
            }
            {
              expr = "avg(rate(node_cpu_seconds_total{${nodeFilter}, mode=\"iowait\"}[$__rate_interval]))";
              legend = "Busy Iowait";
              step = 240;
            }
            {
              expr = "avg(sum without(mode) (rate(node_cpu_seconds_total{${nodeFilter}, mode=~\".*irq\"}[$__rate_interval])))";
              legend = "Busy IRQs";
              step = 240;
            }
            {
              expr = "avg(sum without (mode) (rate(node_cpu_seconds_total{${nodeFilter},  mode!='idle',mode!='user',mode!='system',mode!='iowait',mode!='irq',mode!='softirq'}[$__rate_interval])))";
              legend = "Busy Other";
              step = 240;
            }
            {
              expr = "avg(rate(node_cpu_seconds_total{${nodeFilter}, mode=\"idle\"}[$__rate_interval]))";
              legend = "Idle";
              step = 240;
            }
          ];
        })
        (mkStackedTimeseries {
          x = 12;
          y = 6;
          title = "Memory Basic";
          unit = "bytes";
          min = 0;
          fillOpacity = 40;
          lineInterpolation = "linear";
          stacking = {
            group = "A";
            mode = "normal";
          };
          legendWidth = 350;
          overrides = [
            {
              matcher = {
                id = "byName";
                options = "Swap used";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#BF1B00";
                    mode = "fixed";
                  };
                }
              ];
            }
            {
              matcher = {
                id = "byName";
                options = "Total";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#E0F9D7";
                    mode = "fixed";
                  };
                }
                {
                  id = "custom.fillOpacity";
                  value = 0;
                }
                {
                  id = "custom.stacking";
                  value = {
                    group = false;
                    mode = "normal";
                  };
                }
              ];
            }
            {
              matcher = {
                id = "byName";
                options = "Cache + Buffer";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#052B51";
                    mode = "fixed";
                  };
                }
              ];
            }
            {
              matcher = {
                id = "byName";
                options = "Free";
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = "#7EB26D";
                    mode = "fixed";
                  };
                }
              ];
            }
          ];
          targets = [
            {
              expr = "node_memory_MemTotal_bytes{${nodeFilter}}";
              legend = "Total";
              step = 240;
            }
            {
              expr = "node_memory_MemTotal_bytes{${nodeFilter}} - node_memory_MemFree_bytes{${nodeFilter}} - (node_memory_Cached_bytes{${nodeFilter}} + node_memory_Buffers_bytes{${nodeFilter}} + node_memory_SReclaimable_bytes{${nodeFilter}})";
              legend = "Used";
              step = 240;
            }
            {
              expr = "node_memory_Cached_bytes{${nodeFilter}} + node_memory_Buffers_bytes{${nodeFilter}} + node_memory_SReclaimable_bytes{${nodeFilter}}";
              legend = "Cache + Buffer";
              step = 240;
            }
            {
              expr = "node_memory_MemFree_bytes{${nodeFilter}}";
              legend = "Free";
              step = 240;
            }
            {
              expr = "(node_memory_SwapTotal_bytes{${nodeFilter}} - node_memory_SwapFree_bytes{${nodeFilter}})";
              legend = "Swap used";
              step = 240;
            }
          ];
        })
        (mkStackedTimeseries {
          x = 0;
          y = 13;
          title = "Network Traffic Basic";
          unit = "bps";
          stacking = {
            group = "A";
            mode = "none";
          };
          overrides = [
            {
              matcher = {
                id = "byRegexp";
                options = "/.*Tx.*/";
              };
              properties = [
                {
                  id = "custom.transform";
                  value = "negative-Y";
                }
              ];
            }
          ];
          targets = [
            {
              expr = "rate(node_network_receive_bytes_total{${nodeFilter}}[$__rate_interval])*8";
              legend = "Rx {{device}}";
              step = 240;
            }
            {
              expr = "rate(node_network_transmit_bytes_total{${nodeFilter}}[$__rate_interval])*8";
              legend = "Tx {{device}}";
              step = 240;
            }
          ];
        })
        (mkStackedTimeseries {
          x = 12;
          y = 13;
          title = "Disk Space Used Basic";
          unit = "percent";
          min = 0;
          max = 100;
          stacking = {
            group = "A";
            mode = "none";
          };
          targets = [
            {
              expr = "((node_filesystem_size_bytes{${nodeFilter}, device!~'rootfs'} - node_filesystem_avail_bytes{${nodeFilter}, device!~'rootfs'}) / node_filesystem_size_bytes{${nodeFilter}, device!~'rootfs'}) * 100";
              legend = "{{mountpoint}}";
              step = 240;
            }
          ];
        })
      ]
      # Row headers — Grafana requires them as their own top-level panels;
      # id gets reassigned by mkDashboard along with everything else.
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
        {
          type = "row";
          title = "Basic CPU / Mem / Net / Disk";
          collapsed = false;
          gridPos = {
            x = 0;
            y = 5;
            w = 24;
            h = 1;
          };
          panels = [];
        }
      ];
  }
