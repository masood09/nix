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
          description = "Overall CPU busy percentage (averaged across all cores)";
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
          description = "System load over all CPU cores together";
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
          description = "Real RAM usage excluding cache and reclaimable memory";
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
          description = "Percentage of swap space currently used by the system";
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
          description = "Used Root FS";
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
          description = "RAM and swap usage overview, including caches";
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
          description = "Per-interface network traffic (receive and transmit) in bits per second";
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
          description = "Percentage of filesystem space used for each mounted device";
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
        {
          type = "row";
          title = "CPU / Memory / Net / Disk";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 20;
            w = 24;
            h = 1;
          };
          panels = let
            byName = name: color: {
              matcher = {
                id = "byName";
                options = name;
              };
              properties = [
                {
                  id = "color";
                  value = {
                    fixedColor = color;
                    mode = "fixed";
                  };
                }
              ];
            };
            negativeY = regex: {
              matcher = {
                id = "byRegexp";
                options = regex;
              };
              properties = [
                {
                  id = "custom.transform";
                  value = "negative-Y";
                }
              ];
            };
          in [
            (mkStackedTimeseries
              {
                x = 0;
                y = 21;
                h = 12;
                title = "CPU";
                description = "CPU time usage split by state, normalized across all CPU cores";
                unit = "percentunit";
                min = 0;
                fillOpacity = 70;
                lineInterpolation = "smooth";
                lineWidth = 2;
                stacking = {
                  group = "A";
                  mode = "percent";
                };
                legendWidth = 250;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                tooltipSort = "desc";
                overrides =
                  [
                    (byName "Idle - Waiting for something to happen" "#052B51")
                    (byName "Iowait - Waiting for I/O to complete" "#EAB839")
                    (byName "Irq - Servicing interrupts" "#BF1B00")
                    (byName "Nice - Niced processes executing in user mode" "#C15C17")
                    (byName "Softirq - Servicing softirqs" "#E24D42")
                    (byName "Steal - Time spent in other operating systems when running in a virtualized environment" "#FCE2DE")
                    (byName "System - Processes executing in kernel mode" "#508642")
                    (byName "User - Normal processes executing in user mode" "#5195CE")
                  ]
                  ++ [
                    {
                      matcher = {
                        id = "byName";
                        options = "Guest CPU usage";
                      };
                      properties = [
                        {
                          id = "custom.fillOpacity";
                          value = 0;
                        }
                        {
                          id = "custom.lineStyle";
                          value = {
                            dash = [10 10];
                            fill = "dash";
                          };
                        }
                        {
                          id = "custom.stacking";
                          value = {
                            group = "A";
                            mode = "none";
                          };
                        }
                      ];
                    }
                  ];
                targets = [
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"system\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "System - Processes executing in kernel mode";
                    step = 240;
                  }
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"user\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "User - Normal processes executing in user mode";
                    step = 240;
                  }
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"nice\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "Nice - Niced processes executing in user mode";
                    step = 240;
                  }
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"iowait\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "Iowait - Waiting for I/O to complete";
                    step = 240;
                  }
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"irq\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "Irq - Servicing interrupts";
                    step = 240;
                  }
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"softirq\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "Softirq - Servicing softirqs";
                    step = 240;
                  }
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"steal\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "Steal - Time spent in other operating systems when running in a virtualized environment";
                    step = 240;
                  }
                  {
                    expr = "sum(rate(node_cpu_seconds_total{mode=\"idle\",${nodeFilter}}[$__rate_interval])) / scalar(count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu)))";
                    legend = "Idle - Waiting for something to happen";
                    step = 240;
                  }
                  {
                    expr = "sum by(instance) (rate(node_cpu_guest_seconds_total{${nodeFilter}}[$__rate_interval])) / on(instance) group_left sum by (instance)((rate(node_cpu_seconds_total{${nodeFilter}}[$__rate_interval]))) > 0";
                    legend = "Guest CPU usage";
                    step = 240;
                  }
                ];
              }
              // {id = 100;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 21;
                h = 12;
                title = "Memory";
                description = "Breakdown of physical memory and swap usage. Hardware-detected memory errors are also displayed";
                unit = "bytes";
                min = 0;
                fillOpacity = 40;
                lineInterpolation = "linear";
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides =
                  [
                    (byName "Apps" "#629E51")
                    (byName "Buffers" "#614D93")
                    (byName "Cache" "#6D1F62")
                    (byName "Free" "#0A437C")
                    (byName "Hardware Corrupted - Amount of RAM that the kernel identified as corrupted / not working" "#CFFAFF")
                    (byName "PageTables" "#0A50A1")
                    (byName "Slab" "#806EB7")
                    (byName "Swap" "#BF1B00")
                    (byName "Unused" "#EAB839")
                    (byName "Unused - Free memory unassigned" "#052B51")
                  ]
                  ++ [
                    {
                      matcher = {
                        id = "byRegexp";
                        options = "/.*Hardware Corrupted - *./";
                      };
                      properties = [
                        {
                          id = "custom.stacking";
                          value = {
                            group = false;
                            mode = "normal";
                          };
                        }
                      ];
                    }
                  ];
                targets = [
                  {
                    expr = "node_memory_MemTotal_bytes{${nodeFilter}} - node_memory_MemFree_bytes{${nodeFilter}} - node_memory_Buffers_bytes{${nodeFilter}} - node_memory_Cached_bytes{${nodeFilter}} - node_memory_Slab_bytes{${nodeFilter}} - node_memory_PageTables_bytes{${nodeFilter}} - node_memory_SwapCached_bytes{${nodeFilter}}";
                    legend = "Apps - Memory used by user-space applications";
                    step = 240;
                  }
                  {
                    expr = "node_memory_PageTables_bytes{${nodeFilter}}";
                    legend = "PageTables - Memory used to map between virtual and physical memory addresses";
                    step = 240;
                  }
                  {
                    expr = "node_memory_SwapCached_bytes{${nodeFilter}}";
                    legend = "SwapCache - Memory that keeps track of pages that have been fetched from swap but not yet been modified";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Slab_bytes{${nodeFilter}}";
                    legend = "Slab - Memory used by the kernel to cache data structures for its own use (caches like inode, dentry, etc)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Cached_bytes{${nodeFilter}}";
                    legend = "Cache - Parked file data (file content) cache";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Buffers_bytes{${nodeFilter}}";
                    legend = "Buffers - Block device (e.g. harddisk) cache";
                    step = 240;
                  }
                  {
                    expr = "node_memory_MemFree_bytes{${nodeFilter}}";
                    legend = "Unused - Free memory unassigned";
                    step = 240;
                  }
                  {
                    expr = "(node_memory_SwapTotal_bytes{${nodeFilter}} - node_memory_SwapFree_bytes{${nodeFilter}})";
                    legend = "Swap - Swap space used";
                    step = 240;
                  }
                  {
                    expr = "node_memory_HardwareCorrupted_bytes{${nodeFilter}}";
                    legend = "Hardware Corrupted - Amount of RAM that the kernel identified as corrupted / not working";
                    step = 240;
                  }
                ];
              }
              // {id = 101;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 433;
                h = 12;
                title = "Network Traffic";
                description = "Incoming and outgoing network traffic per interface";
                unit = "bps";
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [(negativeY "/.*out.*/")];
                targets = [
                  {
                    expr = "rate(node_network_receive_bytes_total{${nodeFilter}}[$__rate_interval])*8";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_network_transmit_bytes_total{${nodeFilter}}[$__rate_interval])*8";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 102;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 433;
                h = 12;
                title = "Network Saturation";
                description = "Network interface utilization as a percentage of its maximum capacity";
                unit = "percentunit";
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [(negativeY "/.*out.*/")];
                targets = [
                  {
                    expr = "(node_network_speed_bytes{${nodeFilter}} > bool 0) * (rate(node_network_receive_bytes_total{${nodeFilter}}[$__rate_interval]) / node_network_speed_bytes{${nodeFilter}})";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                  {
                    expr = "(node_network_speed_bytes{${nodeFilter}} > bool 0) * (rate(node_network_transmit_bytes_total{${nodeFilter}}[$__rate_interval]) / node_network_speed_bytes{${nodeFilter}})";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 103;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 445;
                h = 12;
                title = "Disk IOps";
                description = "Disk I/O operations per second for each device";
                unit = "iops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [(negativeY "/.*Read.*/")];
                targets = [
                  {
                    expr = "rate(node_disk_reads_completed_total{${nodeFilter},device=~\"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+\"}[$__rate_interval])";
                    legend = "{{device}} - Read";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_writes_completed_total{${nodeFilter},device=~\"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+\"}[$__rate_interval])";
                    legend = "{{device}} - Write";
                    step = 240;
                  }
                ];
              }
              // {id = 104;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 445;
                h = 12;
                title = "Disk Throughput";
                description = "Disk I/O throughput per device";
                unit = "Bps";
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [(negativeY "/.*Read.*/")];
                targets = [
                  {
                    expr = "rate(node_disk_read_bytes_total{${nodeFilter},device=~\"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+\"}[$__rate_interval])";
                    legend = "{{device}} - Read";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_written_bytes_total{${nodeFilter},device=~\"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+\"}[$__rate_interval])";
                    legend = "{{device}} - Write";
                    step = 240;
                  }
                ];
              }
              // {id = 105;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 457;
                h = 12;
                title = "Filesystem Space Available";
                description = "Amount of available disk space per mounted filesystem, excluding rootfs. Based on block availability to non-root users";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_filesystem_avail_bytes{${nodeFilter},device!~'rootfs'}";
                    legend = "{{mountpoint}}";
                    step = 240;
                  }
                  {
                    expr = "node_filesystem_free_bytes{${nodeFilter},device!~'rootfs'}";
                    legend = "{{mountpoint}} - Free";
                    step = 240;
                  }
                  {
                    expr = "node_filesystem_size_bytes{${nodeFilter},device!~'rootfs'}";
                    legend = "{{mountpoint}} - Size";
                    step = 240;
                  }
                ];
              }
              // {id = 106;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 457;
                h = 12;
                title = "Filesystem Used";
                description = "Disk usage (used = total - available) per mountpoint";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_filesystem_size_bytes{${nodeFilter},device!~'rootfs'} - node_filesystem_avail_bytes{${nodeFilter},device!~'rootfs'}";
                    legend = "{{mountpoint}}";
                    step = 240;
                  }
                ];
              }
              // {id = 107;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 469;
                h = 12;
                title = "Disk I/O Utilization";
                description = "Percentage of time the disk was actively processing I/O operations";
                unit = "percentunit";
                min = 0;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_disk_io_time_seconds_total{${nodeFilter},device=~\"[a-z]+|nvme[0-9]+n[0-9]+|mmcblk[0-9]+\"} [$__rate_interval])";
                    legend = "{{device}}";
                    step = 240;
                  }
                ];
              }
              // {id = 108;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 469;
                h = 12;
                title = "Pressure Stall Information";
                description = "How often tasks experience CPU, memory, or I/O delays. 'Some' indicates partial slowdown; 'Full' indicates all tasks are stalled. Based on Linux PSI metrics:\nhttps://docs.kernel.org/accounting/psi.html";
                unit = "percentunit";
                fillOpacity = 10;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Some.*/";
                    };
                    properties = [
                      {
                        id = "custom.fillOpacity";
                        value = 0;
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Some.*/";
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
                    expr = "rate(node_pressure_cpu_waiting_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU - Some";
                    step = 240;
                  }
                  {
                    expr = "rate(node_pressure_memory_waiting_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "Memory - Some";
                    step = 240;
                  }
                  {
                    expr = "rate(node_pressure_memory_stalled_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "Memory - Full";
                    step = 240;
                  }
                  {
                    expr = "rate(node_pressure_io_waiting_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "I/O - Some";
                    step = 240;
                  }
                  {
                    expr = "rate(node_pressure_io_stalled_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "I/O - Full";
                    step = 240;
                  }
                  {
                    expr = "rate(node_pressure_irq_stalled_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "IRQ - Full";
                    step = 240;
                  }
                ];
              }
              // {id = 109;})
          ];
        }
      ];
  }
