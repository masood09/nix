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
        {
          type = "row";
          title = "Memory Meminfo";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 21;
            w = 24;
            h = 1;
          };
          panels = let
            byRegexColor = regex: color: {
              matcher = {
                id = "byRegexp";
                options = regex;
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
          in [
            (mkStackedTimeseries
              {
                x = 0;
                y = 732;
                h = 10;
                title = "Memory Committed";
                description = "Displays committed memory usage versus the system's commit limit. Exceeding the limit is allowed under Linux overcommit policies but may increase OOM risks under high load";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*CommitLimit - *./";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#BF1B00";
                          mode = "fixed";
                        };
                      }
                      {
                        id = "custom.fillOpacity";
                        value = 0;
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_memory_Committed_AS_bytes{${nodeFilter}}";
                    legend = "Committed_AS – Memory promised to processes (not necessarily used)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_CommitLimit_bytes{${nodeFilter}}";
                    legend = "CommitLimit - Max allowable committed memory";
                    step = 240;
                  }
                ];
              }
              // {id = 110;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 732;
                h = 10;
                title = "Memory Writeback and Dirty";
                description = "Memory currently dirty (modified but not yet written to disk), being actively written back, or held by writeback buffers. High dirty or writeback memory may indicate disk I/O pressure or delayed flushing";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_Writeback_bytes{${nodeFilter}}";
                    legend = "Writeback – Memory currently being flushed to disk";
                    step = 240;
                  }
                  {
                    expr = "node_memory_WritebackTmp_bytes{${nodeFilter}}";
                    legend = "WritebackTmp – FUSE temporary writeback buffers";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Dirty_bytes{${nodeFilter}}";
                    legend = "Dirty – Memory marked dirty (pending write to disk)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_NFS_Unstable_bytes{${nodeFilter}}";
                    legend = "NFS Unstable – Pages sent to NFS server, awaiting storage commit";
                    step = 240;
                  }
                ];
              }
              // {id = 111;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 932;
                h = 10;
                title = "Memory Slab";
                description = "Kernel slab memory usage, separated into reclaimable and non-reclaimable categories. Reclaimable memory can be freed under memory pressure (e.g., caches), while unreclaimable memory is locked by the kernel for core functions";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_SUnreclaim_bytes{${nodeFilter}}";
                    legend = "SUnreclaim – Non-reclaimable slab memory (kernel objects)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_SReclaimable_bytes{${nodeFilter}}";
                    legend = "SReclaimable – Potentially reclaimable slab memory (e.g., inode cache)";
                    step = 240;
                  }
                ];
              }
              // {id = 112;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 932;
                h = 10;
                title = "Memory Shared and Mapped";
                description = "Memory used for mapped files (such as libraries) and shared memory (shmem and tmpfs), including variants backed by huge pages";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_Mapped_bytes{${nodeFilter}}";
                    legend = "Mapped – Memory mapped from files (e.g., libraries, mmap)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Shmem_bytes{${nodeFilter}}";
                    legend = "Shmem – Shared memory used by processes and tmpfs";
                    step = 240;
                  }
                  {
                    expr = "node_memory_ShmemHugePages_bytes{${nodeFilter}}";
                    legend = "ShmemHugePages – Shared memory (shmem/tmpfs) allocated with HugePages";
                    step = 240;
                  }
                  {
                    expr = "node_memory_ShmemPmdMapped_bytes{${nodeFilter}}";
                    legend = "PMD Mapped – Shmem/tmpfs backed by Transparent HugePages (PMD)";
                    step = 240;
                  }
                ];
              }
              // {id = 113;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 942;
                h = 10;
                title = "Memory LRU Active / Inactive (%)";
                description = "Proportion of memory pages in the kernel's active and inactive LRU lists relative to total RAM. Active pages have been recently used, while inactive pages are less recently accessed but still resident in memory";
                unit = "percentunit";
                min = 0;
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  (byRegexColor "/.*Active.*/" "green")
                  (byRegexColor "/.*Inactive.*/" "dark-blue")
                ];
                targets = [
                  {
                    expr = "(node_memory_Inactive_bytes{${nodeFilter}}) \n/ \n(node_memory_MemTotal_bytes{${nodeFilter}})";
                    legend = "Inactive – Less recently used memory, more likely to be reclaimed";
                    step = 240;
                  }
                  {
                    expr = "(node_memory_Active_bytes{${nodeFilter}}) \n/ \n(node_memory_MemTotal_bytes{${nodeFilter}})\n";
                    legend = "Active – Recently used memory, retained unless under pressure";
                    step = 240;
                  }
                ];
              }
              // {id = 114;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 942;
                h = 10;
                title = "Memory LRU Active / Inactive Detail";
                description = "Breakdown of memory pages in the kernel's active and inactive LRU lists, separated by anonymous (heap, tmpfs) and file-backed (caches, mmap) pages.";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_Inactive_file_bytes{${nodeFilter}}";
                    legend = "Inactive_file - File-backed memory on inactive LRU list";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Inactive_anon_bytes{${nodeFilter}}";
                    legend = "Inactive_anon – Anonymous memory on inactive LRU (incl. tmpfs & swap cache)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Active_file_bytes{${nodeFilter}}";
                    legend = "Active_file - File-backed memory on active LRU list";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Active_anon_bytes{${nodeFilter}}";
                    legend = "Active_anon – Anonymous memory on active LRU (incl. tmpfs & swap cache)";
                    step = 240;
                  }
                ];
              }
              // {id = 115;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 952;
                h = 10;
                title = "Memory Kernel / CPU / IO";
                description = "Tracks kernel memory used for CPU-local structures, per-thread stacks, and bounce buffers used for I/O on DMA-limited devices. These areas are typically small but critical for low-level operations";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_KernelStack_bytes{${nodeFilter}}";
                    legend = "KernelStack – Kernel stack memory (per-thread, non-reclaimable)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Percpu_bytes{${nodeFilter}}";
                    legend = "PerCPU – Dynamically allocated per-CPU memory (used by kernel modules)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Bounce_bytes{${nodeFilter}}";
                    legend = "Bounce Memory – I/O buffer for DMA-limited devices";
                    step = 240;
                  }
                ];
              }
              // {id = 116;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 952;
                h = 10;
                title = "Memory Vmalloc";
                description = "Usage of the kernel's vmalloc area, which provides virtual memory allocations for kernel modules and drivers. Includes total, used, and largest free block sizes";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Total.*/";
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
                        id = "color";
                        value = {
                          fixedColor = "dark-red";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_memory_VmallocChunk_bytes{${nodeFilter}}";
                    legend = "Vmalloc Free Chunk – Largest available block in vmalloc area";
                    step = 240;
                  }
                  {
                    expr = "node_memory_VmallocTotal_bytes{${nodeFilter}}";
                    legend = "Vmalloc Total – Total size of the vmalloc memory area";
                    step = 240;
                  }
                  {
                    expr = "node_memory_VmallocUsed_bytes{${nodeFilter}}";
                    legend = "Vmalloc Used – Portion of vmalloc area currently in use";
                    step = 240;
                  }
                ];
              }
              // {id = 117;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 962;
                h = 10;
                title = "Memory Anonymous";
                description = "Memory used by anonymous pages (not backed by files), including standard and huge page allocations. Includes heap, stack, and memory-mapped anonymous regions";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_AnonHugePages_bytes{${nodeFilter}}";
                    legend = "AnonHugePages – Anonymous memory using HugePages";
                    step = 240;
                  }
                  {
                    expr = "node_memory_AnonPages_bytes{${nodeFilter}}";
                    legend = "AnonPages – Anonymous memory (non-file-backed)";
                    step = 240;
                  }
                ];
              }
              // {id = 118;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 962;
                h = 10;
                title = "Memory Unevictable and MLocked";
                description = "Memory that is locked in RAM and cannot be swapped out. Includes both kernel-unevictable memory and user-level memory locked with mlock()";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_Unevictable_bytes{${nodeFilter}}";
                    legend = "Unevictable – Kernel-pinned memory (not swappable)";
                    step = 240;
                  }
                  {
                    expr = "node_memory_Mlocked_bytes{${nodeFilter}}";
                    legend = "Mlocked – Application-locked memory via mlock()";
                    step = 240;
                  }
                ];
              }
              // {id = 119;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 972;
                h = 10;
                title = "Memory DirectMap";
                description = "How much memory is directly mapped in the kernel using different page sizes (4K, 2M, 1G). Helps monitor large page utilization in the direct map region";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_memory_DirectMap1G_bytes{${nodeFilter}}";
                    legend = "DirectMap 1G – Memory mapped with 1GB pages";
                    step = 240;
                  }
                  {
                    expr = "node_memory_DirectMap2M_bytes{${nodeFilter}}";
                    legend = "DirectMap 2M – Memory mapped with 2MB pages";
                    step = 240;
                  }
                  {
                    expr = "node_memory_DirectMap4k_bytes{${nodeFilter}}";
                    legend = "DirectMap 4K – Memory mapped with 4KB pages";
                    step = 240;
                  }
                ];
              }
              // {id = 120;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 972;
                h = 10;
                title = "Memory HugePages";
                description = "Displays HugePages memory usage in bytes, including allocated, free, reserved, and surplus memory. All values are calculated based on the number of huge pages multiplied by their configured size";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "(node_memory_HugePages_Total{${nodeFilter}} - node_memory_HugePages_Free{${nodeFilter}}) * node_memory_Hugepagesize_bytes{${nodeFilter}}";
                    legend = "HugePages Used – Currently allocated";
                    step = 240;
                  }
                  {
                    expr = "node_memory_HugePages_Rsvd{${nodeFilter}} * node_memory_Hugepagesize_bytes{${nodeFilter}}";
                    legend = "HugePages Reserved – Promised but unused";
                    step = 240;
                  }
                  {
                    expr = "node_memory_HugePages_Surp{${nodeFilter}} * node_memory_Hugepagesize_bytes{${nodeFilter}}";
                    legend = "HugePages Surplus – Dynamic pool extension";
                    step = 240;
                  }
                  {
                    expr = "node_memory_HugePages_Total{${nodeFilter}} * node_memory_Hugepagesize_bytes{${nodeFilter}}";
                    legend = "HugePages Total – Reserved memory";
                    step = 240;
                  }
                ];
              }
              // {id = 121;})
          ];
        }
        {
          type = "row";
          title = "Memory Vmstat";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 22;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 733;
                h = 10;
                title = "Memory Pages In / Out";
                description = "Rate of memory pages being read from or written to disk (page-in and page-out operations). High page-out may indicate memory pressure or swapping activity";
                unit = "ops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*out.*/";
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
                    expr = "rate(node_vmstat_pgpgin{${nodeFilter}}[$__rate_interval])";
                    legend = "Pagesin - Page in ops";
                    step = 240;
                  }
                  {
                    expr = "rate(node_vmstat_pgpgout{${nodeFilter}}[$__rate_interval])";
                    legend = "Pagesout - Page out ops";
                    step = 240;
                  }
                ];
              }
              // {id = 122;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 733;
                h = 10;
                title = "Memory Pages Swap In / Out";
                description = "Rate at which memory pages are being swapped in from or out to disk. High swap-out activity may indicate memory pressure";
                unit = "ops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*out.*/";
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
                    expr = "rate(node_vmstat_pswpin{${nodeFilter}}[$__rate_interval])";
                    legend = "Pswpin - Pages swapped in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_vmstat_pswpout{${nodeFilter}}[$__rate_interval])";
                    legend = "Pswpout - Pages swapped out";
                    step = 240;
                  }
                ];
              }
              // {id = 123;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 913;
                h = 10;
                title = "Memory Page Faults";
                description = "Rate of memory page faults, split into total, major (disk-backed), and derived minor (non-disk) faults. High major fault rates may indicate memory pressure or insufficient RAM";
                unit = "ops";
                min = 0;
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendWidth = 350;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "Pgfault - Page major and minor fault ops";
                    };
                    properties = [
                      {
                        id = "custom.fillOpacity";
                        value = 0;
                      }
                      {
                        id = "custom.stacking";
                        value = {
                          group = false;
                          mode = "none";
                        };
                      }
                      {
                        id = "custom.lineStyle";
                        value = {
                          dash = [10 10];
                          fill = "dash";
                        };
                      }
                      {
                        id = "color";
                        value = {
                          fixedColor = "dark-red";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "rate(node_vmstat_pgfault{${nodeFilter}}[$__rate_interval])";
                    legend = "Pgfault - Page major and minor fault ops";
                    step = 240;
                  }
                  {
                    expr = "rate(node_vmstat_pgmajfault{${nodeFilter}}[$__rate_interval])";
                    legend = "Pgmajfault - Major page fault ops";
                    step = 240;
                  }
                  {
                    expr = "rate(node_vmstat_pgfault{${nodeFilter}}[$__rate_interval])  - rate(node_vmstat_pgmajfault{${nodeFilter}}[$__rate_interval])";
                    legend = "Pgminfault - Minor page fault ops";
                    step = 240;
                  }
                ];
              }
              // {id = 124;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 913;
                h = 10;
                title = "OOM Killer";
                description = "Rate of Out-of-Memory (OOM) kill events. A non-zero value indicates the kernel has terminated one or more processes due to memory exhaustion";
                unit = "ops";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "OOM Kills";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "dark-red";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "rate(node_vmstat_oom_kill{${nodeFilter}}[$__rate_interval])";
                    legend = "OOM Kills";
                    step = 240;
                  }
                ];
              }
              // {id = 125;})
          ];
        }
      ];
  }
