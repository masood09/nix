# Host Info — rebuilt from Nix attrsets instead of vendored upstream JSON,
# one section at a time. Derived from the "Node Exporter Full" community
# dashboard (https://grafana.com/grafana/dashboards/1860), rev 45
# (https://grafana.com/api/dashboards/1860/revisions/45/download), which this
# fully replaces — the community dashboard is no longer provisioned.
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
    from = "now-24h"; # matches upstream's default time range
    graphTooltip = 1; # matches upstream: shared crosshair across panels
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
        {
          type = "row";
          title = "System Timesync";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 23;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 734;
                h = 10;
                title = "Time Synchronized Drift";
                description = "Tracks the system clock's estimated and maximum error, as well as its offset from the reference clock (e.g., via NTP). Useful for detecting synchronization drift";
                unit = "s";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_timex_estimated_error_seconds{${nodeFilter}}";
                    legend = "Estimated error";
                    step = 240;
                  }
                  {
                    expr = "node_timex_offset_seconds{${nodeFilter}}";
                    legend = "Offset local vs reference";
                    step = 240;
                  }
                  {
                    expr = "node_timex_maxerror_seconds{${nodeFilter}}";
                    legend = "Maximum error";
                    step = 240;
                  }
                ];
              }
              // {id = 126;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 734;
                h = 10;
                title = "Time PLL Adjust";
                description = "NTP phase-locked loop (PLL) time constant used by the kernel to control time adjustments. Lower values mean faster correction but less stability";
                unit = "short";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_timex_loop_time_constant{${nodeFilter}}";
                    legend = "PLL Time Constant";
                    step = 240;
                  }
                ];
              }
              // {id = 127;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 884;
                h = 10;
                title = "Time Synchronized Status";
                description = "Shows whether the system clock is synchronized to a reliable time source, and the current frequency correction ratio applied by the kernel to maintain synchronization";
                unit = "short";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_timex_sync_status{${nodeFilter}}";
                    legend = "Sync status (1 = ok)";
                    step = 240;
                  }
                  {
                    expr = "node_timex_frequency_adjustment_ratio{${nodeFilter}}";
                    legend = "Frequency Adjustment";
                    step = 240;
                  }
                  {
                    expr = "node_timex_tick_seconds{${nodeFilter}}";
                    legend = "Tick Interval";
                    step = 240;
                  }
                  {
                    expr = "node_timex_tai_offset_seconds{${nodeFilter}}";
                    legend = "TAI Offset";
                    step = 240;
                  }
                ];
              }
              // {id = 128;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 884;
                h = 10;
                title = "PPS Frequency / Stability";
                description = "Displays the PPS signal's frequency offset and stability (jitter) in hertz. Useful for monitoring high-precision time sources like GPS or atomic clocks";
                unit = "hertz";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_timex_pps_frequency_hertz{${nodeFilter}}";
                    legend = "PPS Frequency Offset";
                    step = 240;
                  }
                  {
                    expr = "node_timex_pps_stability_hertz{${nodeFilter}}";
                    legend = "PPS Frequency Stability";
                    step = 240;
                  }
                ];
              }
              // {id = 129;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 894;
                h = 10;
                title = "PPS Time Accuracy";
                description = "Tracks PPS signal timing jitter and shift compared to system clock";
                unit = "s";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_timex_pps_jitter_seconds{${nodeFilter}}";
                    legend = "PPS Jitter";
                    step = 240;
                  }
                  {
                    expr = "node_timex_pps_shift_seconds{${nodeFilter}}";
                    legend = "PPS Shift";
                    step = 240;
                  }
                ];
              }
              // {id = 130;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 894;
                h = 10;
                title = "PPS Sync Events";
                description = "Rate of PPS synchronization diagnostics including calibration events, jitter violations, errors, and frequency stability exceedances";
                unit = "ops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_timex_pps_calibration_total{${nodeFilter}}[$__rate_interval])";
                    legend = "PPS Calibrations/sec";
                    step = 240;
                  }
                  {
                    expr = "rate(node_timex_pps_error_total{${nodeFilter}}[$__rate_interval])";
                    legend = "PPS Errors/sec";
                    step = 240;
                  }
                  {
                    expr = "rate(node_timex_pps_stability_exceeded_total{${nodeFilter}}[$__rate_interval])";
                    legend = "PPS Stability Exceeded/sec";
                    step = 240;
                  }
                  {
                    expr = "rate(node_timex_pps_jitter_total{${nodeFilter}}[$__rate_interval])";
                    legend = "PPS Jitter Events/sec";
                    step = 240;
                  }
                ];
              }
              // {id = 131;})
          ];
        }
        {
          type = "row";
          title = "System Processes";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 24;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 735;
                h = 10;
                title = "Processes Status";
                description = "Processes currently in runnable or blocked states. Helps identify CPU contention or I/O wait bottlenecks.";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_procs_blocked{${nodeFilter}}";
                    legend = "Blocked (I/O Wait)";
                    step = 240;
                  }
                  {
                    expr = "node_procs_running{${nodeFilter}}";
                    legend = "Runnable (Ready for CPU)";
                    step = 240;
                  }
                ];
              }
              // {id = 132;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 735;
                h = 10;
                title = "Processes Detailed States";
                description = "Current number of processes in each state (e.g., running, sleeping, zombie). Requires --collector.processes to be enabled in node_exporter";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "D";
                    };
                    properties = [
                      {
                        id = "displayName";
                        value = "Uninterruptible Sleeping";
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "I";
                    };
                    properties = [
                      {
                        id = "displayName";
                        value = "Idle Kernel Thread";
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "R";
                    };
                    properties = [
                      {
                        id = "displayName";
                        value = "Running";
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "S";
                    };
                    properties = [
                      {
                        id = "displayName";
                        value = "Interruptible Sleeping";
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "T";
                    };
                    properties = [
                      {
                        id = "displayName";
                        value = "Stopped";
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "X";
                    };
                    properties = [
                      {
                        id = "displayName";
                        value = "Dead";
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "Z";
                    };
                    properties = [
                      {
                        id = "displayName";
                        value = "Zombie";
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_processes_state{${nodeFilter}}";
                    legend = "{{ state }}";
                    step = 240;
                  }
                ];
              }
              // {id = 133;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 765;
                h = 10;
                title = "Processes Forks";
                description = "Rate of new processes being created on the system (forks/sec).";
                unit = "ops";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_forks_total{${nodeFilter}}[$__rate_interval])";
                    legend = "Process Forks per second";
                    step = 240;
                  }
                ];
              }
              // {id = 134;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 765;
                h = 10;
                title = "CPU Saturation per Core";
                description = "Shows CPU saturation per core, calculated as the proportion of time spent waiting to run relative to total time demanded (running + waiting).";
                unit = "percentunit";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*waiting.*/";
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
                    expr = "rate(node_schedstat_running_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{ cpu }} - Running";
                    step = 240;
                  }
                  {
                    expr = "rate(node_schedstat_waiting_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{cpu}} - Waiting Queue";
                    step = 240;
                  }
                  {
                    expr = "((rate(node_schedstat_running_seconds_total{${nodeFilter}}[$__rate_interval]) + rate(node_schedstat_waiting_seconds_total{${nodeFilter}}[$__rate_interval])) > bool 0) * (rate(node_schedstat_waiting_seconds_total{${nodeFilter}}[$__rate_interval]) / (rate(node_schedstat_running_seconds_total{${nodeFilter}}[$__rate_interval]) + rate(node_schedstat_waiting_seconds_total{${nodeFilter}}[$__rate_interval])))";
                    legend = "CPU {{cpu}}";
                    step = 240;
                  }
                ];
              }
              // {id = 135;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 775;
                h = 10;
                title = "PIDs Number and Limit";
                description = "Number of active PIDs on the system and the configured maximum allowed. Useful for detecting PID exhaustion risk. Requires --collector.processes in node_exporter";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "PIDs limit";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#F2495C";
                          mode = "fixed";
                        };
                      }
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
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_processes_pids{${nodeFilter}}";
                    legend = "Number of PIDs";
                    step = 240;
                  }
                  {
                    expr = "node_processes_max_processes{${nodeFilter}}";
                    legend = "PIDs limit";
                    step = 240;
                  }
                ];
              }
              // {id = 136;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 775;
                h = 10;
                title = "Threads Number and Limit";
                description = "Number of active threads on the system and the configured thread limit. Useful for monitoring thread pressure. Requires --collector.processes in node_exporter";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "Threads limit";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#F2495C";
                          mode = "fixed";
                        };
                      }
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
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_processes_threads{${nodeFilter}}";
                    legend = "Allocated threads";
                    step = 240;
                  }
                  {
                    expr = "node_processes_max_threads{${nodeFilter}}";
                    legend = "Threads limit";
                    step = 240;
                  }
                ];
              }
              // {id = 137;})
          ];
        }
        {
          type = "row";
          title = "System Misc";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 25;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 816;
                h = 10;
                title = "Context Switches / Interrupts";
                description = "Per-second rate of context switches and hardware interrupts. High values may indicate intense CPU or I/O activity";
                unit = "ops";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_context_switches_total{${nodeFilter}}[$__rate_interval])";
                    legend = "Context switches";
                    step = 240;
                  }
                  {
                    expr = "rate(node_intr_total{${nodeFilter}}[$__rate_interval])";
                    legend = "Interrupts";
                    step = 240;
                  }
                ];
              }
              // {id = 138;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 816;
                h = 10;
                title = "System Load";
                description = "System load average over 1, 5, and 15 minutes. Reflects the number of active or waiting processes. Values above CPU core count may indicate overload";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "CPU Core Count";
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
                    expr = "node_load1{${nodeFilter}}";
                    legend = "Load 1m";
                    step = 240;
                  }
                  {
                    expr = "node_load5{${nodeFilter}}";
                    legend = "Load 5m";
                    step = 240;
                  }
                  {
                    expr = "node_load15{${nodeFilter}}";
                    legend = "Load 15m";
                    step = 240;
                  }
                  {
                    expr = "count(count(node_cpu_seconds_total{${nodeFilter}}) by (cpu))";
                    legend = "CPU Core Count";
                    step = 240;
                  }
                ];
              }
              // {id = 139;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 826;
                h = 10;
                title = "CPU Frequency Scaling";
                description = "Real-time CPU frequency scaling per core, including average minimum and maximum allowed scaling frequencies";
                unit = "hertz";
                fillOpacity = 0;
                tooltipSort = "desc";
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "Max";
                    };
                    properties = [
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
                      {
                        id = "custom.hideFrom";
                        value = {
                          legend = true;
                          tooltip = false;
                          viz = false;
                        };
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "Min";
                    };
                    properties = [
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
                          fixedColor = "blue";
                          mode = "fixed";
                        };
                      }
                      {
                        id = "custom.hideFrom";
                        value = {
                          legend = true;
                          tooltip = false;
                          viz = false;
                        };
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_cpu_scaling_frequency_hertz{${nodeFilter}}";
                    legend = "CPU {{ cpu }}";
                    step = 240;
                  }
                  {
                    expr = "avg(node_cpu_scaling_frequency_max_hertz{${nodeFilter}})";
                    legend = "Max";
                    step = 240;
                  }
                  {
                    expr = "avg(node_cpu_scaling_frequency_min_hertz{${nodeFilter}})";
                    legend = "Min";
                    step = 240;
                  }
                ];
              }
              // {id = 140;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 826;
                h = 10;
                title = "CPU Schedule Timeslices";
                description = "Rate of scheduling timeslices executed per CPU. Reflects how frequently the scheduler switches tasks on each core";
                unit = "ops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_schedstat_timeslices_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{ cpu }}";
                    step = 240;
                  }
                ];
              }
              // {id = 141;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 836;
                h = 10;
                title = "IRQ Detail";
                description = "Breaks down hardware interrupts by type and device. Useful for diagnosing IRQ load on network, disk, or CPU interfaces. Requires --collector.interrupts to be enabled in node_exporter";
                unit = "ops";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_interrupts_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{ type }} - {{ info }}";
                    step = 240;
                  }
                ];
              }
              // {id = 142;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 836;
                h = 10;
                title = "Entropy";
                description = "Number of bits of entropy currently available to the system's random number generators (e.g., /dev/random). Low values may indicate that random number generation could block or degrade performance of cryptographic operations";
                unit = "decbits";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "Entropy pool max";
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
                    expr = "node_entropy_available_bits{${nodeFilter}}";
                    legend = "Entropy available";
                    step = 240;
                  }
                  {
                    expr = "node_entropy_pool_size_bits{${nodeFilter}}";
                    legend = "Entropy pool max";
                    step = 240;
                  }
                ];
              }
              // {id = 143;})
          ];
        }
        {
          type = "row";
          title = "Hardware Misc";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 26;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 737;
                h = 10;
                title = "Hardware Temperature Monitor";
                description = "Monitors hardware sensor temperatures and critical thresholds as exposed by Linux hwmon. Includes CPU, GPU, and motherboard sensors where available";
                unit = "celsius";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Critical.*/";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#E24D42";
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
                    expr = "node_hwmon_temp_celsius{${nodeFilter}} * on(chip) group_left(chip_name) node_hwmon_chip_names{${nodeFilter}}";
                    legend = "{{ chip_name }} {{ sensor }}";
                    step = 240;
                  }
                  {
                    expr = "node_hwmon_temp_crit_alarm_celsius{${nodeFilter}} * on(chip) group_left(chip_name) node_hwmon_chip_names{${nodeFilter}}";
                    legend = "{{ chip_name }} {{ sensor }} Critical Alarm";
                    step = 240;
                  }
                  {
                    expr = "node_hwmon_temp_crit_celsius{${nodeFilter}} * on(chip) group_left(chip_name) node_hwmon_chip_names{${nodeFilter}}";
                    legend = "{{ chip_name }} {{ sensor }} Critical";
                    step = 240;
                  }
                  {
                    expr = "node_hwmon_temp_crit_hyst_celsius{${nodeFilter}} * on(chip) group_left(chip_name) node_hwmon_chip_names{${nodeFilter}}";
                    legend = "{{ chip_name }} {{ sensor }} Critical Hysteresis";
                    step = 240;
                  }
                  {
                    expr = "node_hwmon_temp_max_celsius{${nodeFilter}} * on(chip) group_left(chip_name) node_hwmon_chip_names{${nodeFilter}}";
                    legend = "{{ chip_name }} {{ sensor }} Max";
                    step = 240;
                  }
                ];
              }
              // {id = 144;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 737;
                h = 10;
                title = "Cooling Device Utilization";
                description = "Shows how hard each cooling device (fan/throttle) is working relative to its maximum capacity";
                unit = "percent";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Max.*/";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#EF843C";
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
                    expr = "(node_cooling_device_max_state{${nodeFilter}} > bool 0) * (100 * node_cooling_device_cur_state{${nodeFilter}} / node_cooling_device_max_state{${nodeFilter}})";
                    legend = "{{name}} - {{type}}";
                    step = 240;
                  }
                ];
              }
              // {id = 145;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 747;
                h = 10;
                title = "Power Supply";
                description = "Shows the online status of power supplies (e.g., AC, battery). A value of 1-Yes indicates the power supply is active/online";
                unit = "bool_yes_no";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_power_supply_online{${nodeFilter}}";
                    legend = "{{ power_supply }} online";
                    step = 240;
                  }
                ];
              }
              // {id = 146;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 747;
                h = 10;
                title = "Hardware Fan Speed";
                description = "Displays the current fan speeds (RPM) from hardware sensors via the hwmon interface";
                unit = "rotrpm";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_hwmon_fan_rpm{${nodeFilter}} * on(chip) group_left(chip_name) node_hwmon_chip_names{${nodeFilter}}";
                    legend = "{{ chip_name }} {{ sensor }}";
                    step = 240;
                  }
                  {
                    expr = "node_hwmon_fan_min_rpm{${nodeFilter}} * on(chip) group_left(chip_name) node_hwmon_chip_names{${nodeFilter}}";
                    legend = "{{ chip_name }} {{ sensor }} rpm min";
                    step = 240;
                  }
                ];
              }
              // {id = 147;})
          ];
        }
        {
          type = "row";
          title = "Systemd";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 27;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 4228;
                h = 10;
                title = "Systemd Units State";
                description = "Current number of systemd units in each operational state, such as active, failed, inactive, or transitioning";
                unit = "short";
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "Failed";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#F2495C";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "Active";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#73BF69";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "Activating";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#C8F2C2";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "Deactivating";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "orange";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                  {
                    matcher = {
                      id = "byName";
                      options = "Inactive";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "dark-blue";
                          mode = "fixed";
                        };
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_systemd_units{${nodeFilter},state=\"activating\"}";
                    legend = "Activating";
                    step = 240;
                  }
                  {
                    expr = "node_systemd_units{${nodeFilter},state=\"active\"}";
                    legend = "Active";
                    step = 240;
                  }
                  {
                    expr = "node_systemd_units{${nodeFilter},state=\"deactivating\"}";
                    legend = "Deactivating";
                    step = 240;
                  }
                  {
                    expr = "node_systemd_units{${nodeFilter},state=\"failed\"}";
                    legend = "Failed";
                    step = 240;
                  }
                  {
                    expr = "node_systemd_units{${nodeFilter},state=\"inactive\"}";
                    legend = "Inactive";
                    step = 240;
                  }
                ];
              }
              // {id = 148;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 4228;
                h = 10;
                title = "Systemd Sockets Current";
                description = "Current number of active connections per systemd socket, as reported by the Node Exporter systemd collector";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_systemd_socket_current_connections{${nodeFilter}}";
                    legend = "{{ name }}";
                    step = 240;
                  }
                ];
              }
              // {id = 149;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 4238;
                h = 10;
                title = "Systemd Sockets Accepted";
                description = "Rate of accepted connections per second for each systemd socket";
                unit = "eps";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_systemd_socket_accepted_connections_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{ name }}";
                    step = 240;
                  }
                ];
              }
              // {id = 150;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 4238;
                h = 10;
                title = "Systemd Sockets Refused";
                description = "Rate of systemd socket connection refusals per second, typically due to service unavailability or backlog overflow";
                unit = "eps";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_systemd_socket_refused_connections_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{ name }}";
                    step = 240;
                  }
                ];
              }
              // {id = 151;})
          ];
        }
        {
          type = "row";
          title = "Storage Disk";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 28;
            w = 24;
            h = 1;
          };
          panels = let
            diskOverrides = [
              {
                matcher = {
                  id = "byRegexp";
                  options = "/.*Read.*/";
                };
                properties = [
                  {
                    id = "custom.transform";
                    value = "negative-Y";
                  }
                ];
              }
              {
                matcher = {
                  id = "byRegexp";
                  options = "/sda.*/";
                };
                properties = [
                  {
                    id = "color";
                    value = {
                      fixedColor = "orange";
                      mode = "fixed";
                    };
                  }
                ];
              }
            ];
            sdaOrange = [
              {
                matcher = {
                  id = "byRegexp";
                  options = "/sda.*/";
                };
                properties = [
                  {
                    id = "color";
                    value = {
                      fixedColor = "orange";
                      mode = "fixed";
                    };
                  }
                ];
              }
            ];
          in [
            (mkStackedTimeseries
              {
                x = 0;
                y = 29;
                h = 10;
                title = "Disk Read/Write IOps";
                description = "Number of I/O operations completed per second for the device (after merges), including both reads and writes";
                unit = "iops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = diskOverrides;
                targets = [
                  {
                    expr = "rate(node_disk_reads_completed_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Read";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_writes_completed_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Write";
                    step = 240;
                  }
                ];
              }
              // {id = 152;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 29;
                h = 10;
                title = "Disk Read/Write Data";
                description = "Number of bytes read from or written to the device per second";
                unit = "Bps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = diskOverrides;
                targets = [
                  {
                    expr = "rate(node_disk_read_bytes_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Read";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_written_bytes_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Write";
                    step = 240;
                  }
                ];
              }
              // {id = 153;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 389;
                h = 10;
                title = "Disk Average Wait Time";
                description = "Average time for requests issued to the device to be served. This includes the time spent by the requests in queue and the time spent servicing them.";
                unit = "s";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = diskOverrides;
                targets = [
                  {
                    expr = "(rate(node_disk_reads_completed_total{${nodeFilter}}[$__rate_interval]) > bool 0) * (rate(node_disk_read_time_seconds_total{${nodeFilter}}[$__rate_interval]) / rate(node_disk_reads_completed_total{${nodeFilter}}[$__rate_interval]))";
                    legend = "{{device}} - Read";
                    step = 240;
                  }
                  {
                    expr = "(rate(node_disk_writes_completed_total{${nodeFilter}}[$__rate_interval]) > bool 0) * (rate(node_disk_write_time_seconds_total{${nodeFilter}}[$__rate_interval]) / rate(node_disk_writes_completed_total{${nodeFilter}}[$__rate_interval]))";
                    legend = "{{device}} - Write";
                    step = 240;
                  }
                ];
              }
              // {id = 154;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 389;
                h = 10;
                title = "Average Queue Size";
                description = "Average queue length of the requests that were issued to the device";
                unit = "none";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/sda_*/";
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
                    expr = "rate(node_disk_io_time_weighted_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}}";
                    step = 240;
                  }
                ];
              }
              // {id = 155;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 399;
                h = 10;
                title = "Disk R/W Merged";
                description = "Number of read and write requests merged per second that were queued to the device";
                unit = "iops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = diskOverrides;
                targets = [
                  {
                    expr = "rate(node_disk_reads_merged_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Read";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_writes_merged_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Write";
                    step = 240;
                  }
                ];
              }
              // {id = 156;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 399;
                h = 10;
                title = "Time Spent Doing I/Os";
                description = "Percentage of time the disk spent actively processing I/O operations, including general I/O, discards (TRIM), and write cache flushes";
                unit = "percentunit";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = sdaOrange;
                targets = [
                  {
                    expr = "rate(node_disk_io_time_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - General IO";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_discard_time_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Discard/TRIM";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_flush_requests_time_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Flush (write cache)";
                    step = 240;
                  }
                ];
              }
              // {id = 157;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 409;
                h = 10;
                title = "Disk Ops Discards / Flush";
                description = "Per-second rate of discard (TRIM) and flush (write cache) operations. Useful for monitoring low-level disk activity on SSDs and advanced storage";
                unit = "ops";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = sdaOrange;
                targets = [
                  {
                    expr = "rate(node_disk_discards_completed_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Discards completed";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_discards_merged_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Discards merged";
                    step = 240;
                  }
                  {
                    expr = "rate(node_disk_flush_requests_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Flush";
                    step = 240;
                  }
                ];
              }
              // {id = 158;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 409;
                h = 10;
                title = "Disk Sectors Discarded Successfully";
                description = "Shows how many disk sectors are discarded (TRIMed) per second. Useful for monitoring SSD behavior and storage efficiency";
                unit = "short";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = sdaOrange;
                targets = [
                  {
                    expr = "rate(node_disk_discarded_sectors_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}}";
                    step = 240;
                  }
                ];
              }
              // {id = 159;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 419;
                h = 10;
                title = "Instantaneous Queue Size";
                description = "Number of in-progress I/O requests at the time of sampling (active requests in the disk queue)";
                unit = "none";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = sdaOrange;
                targets = [
                  {
                    expr = "node_disk_io_now{${nodeFilter}}";
                    legend = "{{device}}";
                    step = 240;
                  }
                ];
              }
              // {id = 160;})
          ];
        }
        {
          type = "row";
          title = "Storage Filesystem";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 29;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 30;
                h = 10;
                title = "File Descriptor";
                description = "Number of file descriptors currently allocated system-wide versus the system limit. Important for detecting descriptor exhaustion risks";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Max.*/";
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
                    expr = "node_filefd_maximum{${nodeFilter}}";
                    legend = "Max open files";
                    step = 240;
                  }
                  {
                    expr = "node_filefd_allocated{${nodeFilter}}";
                    legend = "Open files";
                    step = 240;
                  }
                ];
              }
              // {id = 161;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 30;
                h = 10;
                title = "File Nodes Free";
                description = "Number of free file nodes (inodes) available per mounted filesystem. A low count may prevent file creation even if disk space is available";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_filesystem_files_free{${nodeFilter},device!~'rootfs'}";
                    legend = "{{mountpoint}}";
                    step = 240;
                  }
                ];
              }
              // {id = 162;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 370;
                h = 10;
                title = "Filesystem in ReadOnly / Error";
                description = "Indicates filesystems mounted in read-only mode or reporting device-level I/O errors.";
                unit = "bool_yes_no";
                min = 0;
                max = 1;
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_filesystem_readonly{${nodeFilter},device!~'rootfs'}";
                    legend = "{{mountpoint}} - ReadOnly";
                    step = 240;
                  }
                  {
                    expr = "node_filesystem_device_error{${nodeFilter},device!~'rootfs',fstype!~'tmpfs'}";
                    legend = "{{mountpoint}} - Device error";
                    step = 240;
                  }
                ];
              }
              // {id = 163;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 370;
                h = 10;
                title = "File Nodes Size";
                description = "Number of file nodes (inodes) available per mounted filesystem. Reflects maximum file capacity regardless of disk size";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_filesystem_files{${nodeFilter},device!~'rootfs'}";
                    legend = "{{mountpoint}}";
                    step = 240;
                  }
                ];
              }
              // {id = 164;})
          ];
        }
        {
          type = "row";
          title = "Network Traffic";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 30;
            w = 24;
            h = 1;
          };
          panels = let
            outNegativeY = [
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
          in [
            (mkStackedTimeseries
              {
                x = 0;
                y = 31;
                h = 10;
                title = "Network Traffic by Packets";
                description = "Number of network packets received and transmitted per second, by interface.";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_network_receive_packets_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_network_transmit_packets_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 165;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 31;
                h = 10;
                title = "Network Traffic Errors";
                description = "Rate of packet-level errors for each network interface. Receive errors may indicate physical or driver issues; transmit errors may reflect collisions or hardware faults";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_network_receive_errs_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_network_transmit_errs_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 166;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 251;
                h = 10;
                title = "Network Traffic Drop";
                description = "Rate of dropped packets per network interface. Receive drops can indicate buffer overflow or driver issues; transmit drops may result from outbound congestion or queuing limits";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_network_receive_drop_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_network_transmit_drop_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 167;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 251;
                h = 10;
                title = "Network Traffic Compressed";
                description = "Rate of compressed network packets received and transmitted per interface. These are common in low-bandwidth or special interfaces like PPP or SLIP";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_network_receive_compressed_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_network_transmit_compressed_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 168;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 261;
                h = 10;
                title = "Network Traffic Multicast";
                description = "Rate of incoming multicast packets received per network interface. Multicast is used by protocols such as mDNS, SSDP, and some streaming or cluster services";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "rate(node_network_receive_multicast_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                ];
              }
              // {id = 169;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 261;
                h = 10;
                title = "Network Traffic NoHandler";
                description = "Rate of received packets that could not be processed due to missing protocol or handler in the kernel. May indicate unsupported traffic or misconfiguration";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "rate(node_network_receive_nohandler_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                ];
              }
              // {id = 170;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 271;
                h = 10;
                title = "Network Traffic Frame";
                description = "Rate of frame errors on received packets, typically caused by physical layer issues such as bad cables, duplex mismatches, or hardware problems";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "rate(node_network_receive_frame_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                ];
              }
              // {id = 171;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 271;
                h = 10;
                title = "Network Traffic Fifo";
                description = "Tracks FIFO buffer overrun errors on network interfaces. These occur when incoming or outgoing packets are dropped due to queue or buffer overflows, often indicating congestion or hardware limits";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_network_receive_fifo_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_network_transmit_fifo_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 172;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 281;
                h = 10;
                title = "Network Traffic Collision";
                description = "Rate of packet collisions detected during transmission. Mostly relevant on half-duplex or legacy Ethernet networks";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_network_transmit_colls_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 173;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 281;
                h = 10;
                title = "Network Traffic Carrier Errors";
                description = "Rate of carrier errors during transmission. These typically indicate physical layer issues like faulty cabling or duplex mismatches";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "rate(node_network_transmit_carrier_total{${nodeFilter}}[$__rate_interval])";
                    legend = "{{device}} - Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 174;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 291;
                h = 10;
                title = "ARP Entries";
                description = "Number of ARP entries per interface. Useful for detecting excessive ARP traffic or table growth due to scanning or misconfiguration";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_arp_entries{${nodeFilter}}";
                    legend = "{{ device }} ARP Table";
                    step = 240;
                  }
                ];
              }
              // {id = 175;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 291;
                h = 10;
                title = "NF Conntrack";
                description = "Current and maximum connection tracking entries used by Netfilter (nf_conntrack). High usage approaching the limit may cause packet drops or connection issues";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "NF conntrack limit";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "dark-red";
                          mode = "fixed";
                        };
                      }
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
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_nf_conntrack_entries{${nodeFilter}}";
                    legend = "NF conntrack entries";
                    step = 240;
                  }
                  {
                    expr = "node_nf_conntrack_entries_limit{${nodeFilter}}";
                    legend = "NF conntrack limit";
                    step = 240;
                  }
                ];
              }
              // {id = 176;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 301;
                h = 10;
                title = "Network Operational Status";
                description = "Operational and physical link status of each network interface. Values are Yes for 'up' or link present, and No for 'down' or no carrier.";
                unit = "bool_yes_no";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "node_network_up{operstate=\"up\",${nodeFilter}}";
                    legend = "{{interface}} - Operational state UP";
                    step = 240;
                  }
                  {
                    expr = "node_network_carrier{${nodeFilter}}";
                    legend = "{{device}} - Physical link";
                  }
                ];
              }
              // {id = 177;})
            (mkBarGauge
              {
                x = 12;
                y = 301;
                w = 6;
                h = 10;
                title = "Speed";
                description = "Maximum speed of each network interface as reported by the operating system. This is a static hardware capability, not current throughput";
                unit = "bps";
                min = 0;
                max = null;
                decimals = 0;
                instant = false;
                thresholds = [
                  {
                    value = null;
                    color = "green";
                  }
                ];
                targets = [
                  {
                    expr = "node_network_speed_bytes{${nodeFilter}} * 8";
                    legend = "{{ device }}";
                    step = 240;
                  }
                ];
              }
              // {id = 178;})
            (mkBarGauge
              {
                x = 18;
                y = 301;
                w = 6;
                h = 10;
                title = "MTU";
                description = "MTU (Maximum Transmission Unit) in bytes for each network interface. Affects packet size and transmission efficiency";
                unit = "none";
                min = 0;
                max = null;
                decimals = 0;
                instant = false;
                thresholds = [
                  {
                    value = null;
                    color = "green";
                  }
                ];
                targets = [
                  {
                    expr = "node_network_mtu_bytes{${nodeFilter}}";
                    legend = "{{ device }}";
                    step = 240;
                  }
                ];
              }
              // {id = 179;})
          ];
        }
        {
          type = "row";
          title = "Network Sockstat";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 31;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 32;
                h = 10;
                title = "Sockstat TCP";
                description = "Tracks TCP socket usage and memory per node";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "node_sockstat_TCP_alloc{${nodeFilter}}";
                    legend = "Allocated Sockets";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_TCP_inuse{${nodeFilter}}";
                    legend = "In-Use Sockets";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_TCP_orphan{${nodeFilter}}";
                    legend = "Orphaned Sockets";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_TCP_tw{${nodeFilter}}";
                    legend = "TIME_WAIT Sockets";
                    step = 240;
                  }
                ];
              }
              // {id = 180;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 32;
                h = 10;
                title = "Sockstat UDP";
                description = "Number of UDP and UDPLite sockets currently in use";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "node_sockstat_UDPLITE_inuse{${nodeFilter}}";
                    legend = "UDPLite - In-Use Sockets";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_UDP_inuse{${nodeFilter}}";
                    legend = "UDP - In-Use Sockets";
                    step = 240;
                  }
                ];
              }
              // {id = 181;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 42;
                h = 10;
                title = "Sockstat Used";
                description = "Total number of sockets currently in use across all protocols (TCP, UDP, UNIX, etc.), as reported by /proc/net/sockstat";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "node_sockstat_sockets_used{${nodeFilter}}";
                    legend = "Total sockets";
                    step = 240;
                  }
                ];
              }
              // {id = 182;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 42;
                h = 10;
                title = "Sockstat FRAG / RAW";
                description = "Number of FRAG and RAW sockets currently in use. RAW sockets are used for custom protocols or tools like ping; FRAG sockets are used internally for IP packet defragmentation";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "node_sockstat_FRAG_inuse{${nodeFilter}}";
                    legend = "FRAG - In-Use Sockets";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_RAW_inuse{${nodeFilter}}";
                    legend = "RAW - In-Use Sockets";
                    step = 240;
                  }
                ];
              }
              // {id = 183;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 52;
                h = 10;
                title = "Sockstat Memory Size";
                description = "Kernel memory used by TCP, UDP, and IP fragmentation buffers";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "node_sockstat_TCP_mem_bytes{${nodeFilter}}";
                    legend = "TCP";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_UDP_mem_bytes{${nodeFilter}}";
                    legend = "UDP";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_FRAG_memory{${nodeFilter}}";
                    legend = "Fragmentation";
                  }
                ];
              }
              // {id = 184;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 52;
                h = 10;
                title = "Sockstat Average Socket Memory";
                description = "Average memory used per socket (TCP/UDP). Helps tune net.ipv4.tcp_rmem / tcp_wmem";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "(node_sockstat_TCP_inuse{${nodeFilter}} > bool 0) * (node_sockstat_TCP_mem_bytes{${nodeFilter}} / node_sockstat_TCP_inuse{${nodeFilter}})";
                    legend = "TCP";
                    step = 240;
                  }
                  {
                    expr = "(node_sockstat_UDP_inuse{${nodeFilter}} > bool 0) * (node_sockstat_UDP_mem_bytes{${nodeFilter}} / node_sockstat_UDP_inuse{${nodeFilter}})";
                    legend = "UDP";
                    step = 240;
                  }
                ];
              }
              // {id = 185;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 62;
                h = 10;
                title = "TCP/UDP Kernel Buffer Memory Pages";
                description = "TCP/UDP socket memory usage in kernel (in pages)";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "node_sockstat_TCP_mem{${nodeFilter}}";
                    legend = "TCP";
                    step = 240;
                  }
                  {
                    expr = "node_sockstat_UDP_mem{${nodeFilter}}";
                    legend = "UDP";
                    step = 240;
                  }
                ];
              }
              // {id = 186;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 62;
                h = 10;
                title = "Softnet Packets";
                description = "Packets processed and dropped by the softnet network stack per CPU. Drops may indicate CPU saturation or network driver limitations";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Dropped.*/";
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
                    expr = "rate(node_softnet_processed_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{cpu}} - Processed";
                    step = 240;
                  }
                  {
                    expr = "rate(node_softnet_dropped_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{cpu}} - Dropped";
                    step = 240;
                  }
                ];
              }
              // {id = 187;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 72;
                h = 10;
                title = "Softnet Out of Quota";
                description = "How often the kernel was unable to process all packets in the softnet queue before time ran out. Frequent squeezes may indicate CPU contention or driver inefficiency";
                unit = "eps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                targets = [
                  {
                    expr = "rate(node_softnet_times_squeezed_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{cpu}} - Times Squeezed";
                    step = 240;
                  }
                ];
              }
              // {id = 188;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 72;
                h = 10;
                title = "Softnet RPS";
                description = "Tracks the number of packets processed or dropped by Receive Packet Steering (RPS), a mechanism to distribute packet processing across CPUs";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Dropped.*/";
                    };
                    properties = [
                      {
                        id = "custom.transform";
                        value = "negative-Y";
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
                    expr = "rate(node_softnet_received_rps_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{cpu}} - Processed";
                    step = 240;
                  }
                  {
                    expr = "rate(node_softnet_flow_limit_count_total{${nodeFilter}}[$__rate_interval])";
                    legend = "CPU {{cpu}} - Dropped";
                    step = 240;
                  }
                ];
              }
              // {id = 189;})
          ];
        }
        {
          type = "row";
          title = "Network Netstat";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 32;
            w = 24;
            h = 1;
          };
          panels = let
            outNegativeY = [
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
          in [
            (mkStackedTimeseries
              {
                x = 0;
                y = 163;
                h = 10;
                title = "Netstat IP In / Out Octets";
                description = "Rate of octets sent and received at the IP layer, as reported by /proc/net/netstat";
                unit = "Bps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                legendWidth = 300;
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_netstat_IpExt_InOctets{${nodeFilter}}[$__rate_interval])";
                    legend = "IP Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_IpExt_OutOctets{${nodeFilter}}[$__rate_interval])";
                    legend = "IP Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 190;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 163;
                h = 10;
                title = "TCP In / Out";
                description = "Rate of TCP segments sent and received per second, including data and control segments";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_netstat_Tcp_InSegs{${nodeFilter}}[$__rate_interval])";
                    legend = "TCP Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_Tcp_OutSegs{${nodeFilter}}[$__rate_interval])";
                    legend = "TCP Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 191;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 193;
                h = 10;
                title = "UDP In / Out";
                description = "Rate of UDP datagrams sent and received per second, based on /proc/net/netstat";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_netstat_Udp_InDatagrams{${nodeFilter}}[$__rate_interval])";
                    legend = "UDP Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_Udp_OutDatagrams{${nodeFilter}}[$__rate_interval])";
                    legend = "UDP Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 192;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 193;
                h = 10;
                title = "ICMP In / Out";
                description = "Number of ICMP messages sent and received per second, including error and control messages";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = outNegativeY;
                targets = [
                  {
                    expr = "rate(node_netstat_Icmp_InMsgs{${nodeFilter}}[$__rate_interval])";
                    legend = "ICMP Rx in";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_Icmp_OutMsgs{${nodeFilter}}[$__rate_interval])";
                    legend = "ICMP Tx out";
                    step = 240;
                  }
                ];
              }
              // {id = 193;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 203;
                h = 10;
                title = "TCP Errors";
                description = "Tracks various TCP error and congestion-related events, including retransmissions, timeouts, dropped connections, and buffer issues";
                unit = "pps";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_netstat_TcpExt_ListenOverflows{${nodeFilter}}[$__rate_interval])";
                    legend = "Listen Overflows";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_TcpExt_ListenDrops{${nodeFilter}}[$__rate_interval])";
                    legend = "Listen Drops";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_TcpExt_TCPSynRetrans{${nodeFilter}}[$__rate_interval])";
                    legend = "SYN Retransmits";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_Tcp_RetransSegs{${nodeFilter}}[$__rate_interval])";
                    legend = "Segment Retransmits";
                  }
                  {
                    expr = "rate(node_netstat_Tcp_InErrs{${nodeFilter}}[$__rate_interval])";
                    legend = "Receive Errors";
                  }
                  {
                    expr = "rate(node_netstat_Tcp_OutRsts{${nodeFilter}}[$__rate_interval])";
                    legend = "RST Sent";
                  }
                  {
                    expr = "rate(node_netstat_TcpExt_TCPRcvQDrop{${nodeFilter}}[$__rate_interval])";
                    legend = "Receive Queue Drops";
                  }
                  {
                    expr = "rate(node_netstat_TcpExt_TCPOFOQueue{${nodeFilter}}[$__rate_interval])";
                    legend = "Out-of-order Queued";
                  }
                  {
                    expr = "rate(node_netstat_TcpExt_TCPTimeouts{${nodeFilter}}[$__rate_interval])";
                    legend = "TCP Timeouts";
                  }
                ];
              }
              // {id = 194;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 203;
                h = 10;
                title = "UDP Errors";
                description = "Rate of UDP and UDPLite datagram delivery errors, including missing listeners, buffer overflows, and protocol-specific issues";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_netstat_Udp_InErrors{${nodeFilter}}[$__rate_interval])";
                    legend = "UDP Rx in Errors";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_Udp_NoPorts{${nodeFilter}}[$__rate_interval])";
                    legend = "UDP No Listener";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_UdpLite_InErrors{${nodeFilter}}[$__rate_interval])";
                    legend = "UDPLite Rx in Errors";
                  }
                  {
                    expr = "rate(node_netstat_Udp_RcvbufErrors{${nodeFilter}}[$__rate_interval])";
                    legend = "UDP Rx in Buffer Errors";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_Udp_SndbufErrors{${nodeFilter}}[$__rate_interval])";
                    legend = "UDP Tx out Buffer Errors";
                    step = 240;
                  }
                ];
              }
              // {id = 195;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 213;
                h = 10;
                title = "ICMP Errors";
                description = "Rate of incoming ICMP messages that contained protocol-specific errors, such as bad checksums or invalid lengths";
                unit = "pps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_netstat_Icmp_InErrors{${nodeFilter}}[$__rate_interval])";
                    legend = "ICMP Rx In";
                    step = 240;
                  }
                ];
              }
              // {id = 196;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 213;
                h = 10;
                title = "TCP SynCookie";
                description = "Rate of TCP SYN cookies sent, validated, and failed. These are used to protect against SYN flood attacks and manage TCP handshake resources under load";
                unit = "eps";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Failed.*/";
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
                    expr = "rate(node_netstat_TcpExt_SyncookiesFailed{${nodeFilter}}[$__rate_interval])";
                    legend = "SYN Cookies Failed";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_TcpExt_SyncookiesRecv{${nodeFilter}}[$__rate_interval])";
                    legend = "SYN Cookies Validated";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_TcpExt_SyncookiesSent{${nodeFilter}}[$__rate_interval])";
                    legend = "SYN Cookies Sent";
                    step = 240;
                  }
                ];
              }
              // {id = 197;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 223;
                h = 10;
                title = "TCP Connections";
                description = "Number of currently established TCP connections and the system's max supported limit. On Linux, MaxConn may return -1 to indicate a dynamic/unlimited configuration";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Max.*/";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#890F02";
                          mode = "fixed";
                        };
                      }
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
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "node_netstat_Tcp_CurrEstab{${nodeFilter}}";
                    legend = "Current Connections";
                    step = 240;
                  }
                  {
                    expr = "node_netstat_Tcp_MaxConn{${nodeFilter}}";
                    legend = "Max Connections";
                    step = 240;
                  }
                ];
              }
              // {id = 198;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 223;
                h = 10;
                title = "UDP Queue";
                description = "Number of UDP packets currently queued in the receive (RX) and transmit (TX) buffers. A growing queue may indicate a bottleneck";
                unit = "short";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_udp_queues{${nodeFilter},ip=\"v4\",queue=\"rx\"}";
                    legend = "UDP Rx in Queue";
                    step = 240;
                  }
                  {
                    expr = "node_udp_queues{${nodeFilter},ip=\"v4\",queue=\"tx\"}";
                    legend = "UDP Tx out Queue";
                    step = 240;
                  }
                ];
              }
              // {id = 199;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 233;
                h = 10;
                title = "TCP Direct Transition";
                description = "Rate of TCP connection initiations per second. 'Active' opens are initiated by this host. 'Passive' opens are accepted from incoming connections";
                unit = "eps";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(node_netstat_Tcp_ActiveOpens{${nodeFilter}}[$__rate_interval])";
                    legend = "Active Opens";
                    step = 240;
                  }
                  {
                    expr = "rate(node_netstat_Tcp_PassiveOpens{${nodeFilter}}[$__rate_interval])";
                    legend = "Passive Opens";
                    step = 240;
                  }
                ];
              }
              // {id = 200;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 233;
                h = 10;
                title = "TCP Stat Persistent";
                description = "Number of TCP sockets in key connection states. Requires the --collector.tcpstat flag on node_exporter";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_tcp_connection_states{state=\"established\",${nodeFilter}}";
                    legend = "Established";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"fin_wait2\",${nodeFilter}}";
                    legend = "FIN_WAIT2";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"listen\",${nodeFilter}}";
                    legend = "Listen";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"time_wait\",${nodeFilter}}";
                    legend = "TIME_WAIT";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"close_wait\", ${nodeFilter}}";
                    legend = "CLOSE_WAIT";
                    step = 240;
                  }
                ];
              }
              // {id = 201;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 243;
                h = 10;
                title = "TCP Stat Transient";
                description = "Transient TCP connection states. These are typically short-lived during connection establishment and teardown";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_tcp_connection_states{state=\"syn_sent\",${nodeFilter}}";
                    legend = "SYN_SENT";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"syn_recv\",${nodeFilter}}";
                    legend = "SYN_RECV";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"fin_wait1\",${nodeFilter}}";
                    legend = "FIN_WAIT1";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"close\",${nodeFilter}}";
                    legend = "CLOSE";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"last_ack\",${nodeFilter}}";
                    legend = "LAST_ACK";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"closing\",${nodeFilter}}";
                    legend = "CLOSING";
                    step = 240;
                  }
                ];
              }
              // {id = 202;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 243;
                h = 10;
                title = "TCP Socket Queue";
                description = "TCP socket queue sizes. High rx_queued_bytes indicates application not reading fast enough. High tx_queued_bytes indicates network congestion or slow receiver";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_tcp_connection_states{state=\"rx_queued_bytes\",${nodeFilter}}";
                    legend = "RX Queued (waiting to be read)";
                    step = 240;
                  }
                  {
                    expr = "node_tcp_connection_states{state=\"tx_queued_bytes\",${nodeFilter}}";
                    legend = "TX Queued (waiting to be sent)";
                    step = 240;
                  }
                ];
              }
              // {id = 203;})
          ];
        }
        {
          type = "row";
          title = "Node Exporter";
          collapsed = true;
          gridPos = {
            x = 0;
            y = 33;
            w = 24;
            h = 1;
          };
          panels = [
            (mkStackedTimeseries
              {
                x = 0;
                y = 164;
                h = 10;
                title = "Node Exporter Scrape Time";
                description = "Duration of each individual collector executed during a Node Exporter scrape. Useful for identifying slow or failing collectors";
                unit = "s";
                fillOpacity = 20;
                stacking = {
                  group = "A";
                  mode = "normal";
                };
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "node_scrape_collector_duration_seconds{${nodeFilter}}";
                    legend = "{{collector}}";
                    step = 240;
                  }
                ];
              }
              // {id = 204;})
            (mkStackedTimeseries
              {
                x = 12;
                y = 164;
                h = 10;
                title = "Exporter Process CPU Usage";
                description = "Rate of CPU time used by the process exposing this metric (user + system mode)";
                unit = "percentunit";
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                targets = [
                  {
                    expr = "rate(process_cpu_seconds_total{${nodeFilter}}[$__rate_interval])";
                    legend = "Process CPU Usage";
                    step = 240;
                  }
                ];
              }
              // {id = 205;})
            (mkStackedTimeseries
              {
                x = 0;
                y = 174;
                w = 10;
                h = 10;
                title = "Exporter Processes Memory";
                description = "Tracks the memory usage of the process exposing this metric (e.g., node_exporter), including current virtual memory and maximum virtual memory limit";
                unit = "bytes";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byName";
                      options = "Virtual Memory Limit";
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
                  {
                    __systemRef = "hideSeriesFrom";
                    matcher = {
                      id = "byNames";
                      options = {
                        mode = "exclude";
                        names = ["Virtual Memory"];
                        prefix = "All except:";
                        readOnly = true;
                      };
                    };
                    properties = [
                      {
                        id = "custom.hideFrom";
                        value = {
                          legend = false;
                          tooltip = false;
                          viz = true;
                        };
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "process_virtual_memory_bytes{${nodeFilter}}";
                    legend = "Virtual Memory";
                    step = 240;
                  }
                  {
                    expr = "process_virtual_memory_max_bytes{${nodeFilter}}";
                    legend = "Virtual Memory Limit";
                    step = 240;
                  }
                ];
              }
              // {id = 206;})
            (mkStackedTimeseries
              {
                x = 10;
                y = 174;
                w = 10;
                h = 10;
                title = "Exporter File Descriptor Usage";
                description = "Number of file descriptors used by the exporter process versus its configured limit";
                unit = "short";
                min = 0;
                fillOpacity = 20;
                legendCalcs = ["min" "mean" "max"];
                legendDisplayMode = "table";
                overrides = [
                  {
                    matcher = {
                      id = "byRegexp";
                      options = "/.*Max.*/";
                    };
                    properties = [
                      {
                        id = "color";
                        value = {
                          fixedColor = "#890F02";
                          mode = "fixed";
                        };
                      }
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
                    ];
                  }
                  {
                    __systemRef = "hideSeriesFrom";
                    matcher = {
                      id = "byNames";
                      options = {
                        mode = "exclude";
                        names = ["Open file descriptors"];
                        prefix = "All except:";
                        readOnly = true;
                      };
                    };
                    properties = [
                      {
                        id = "custom.hideFrom";
                        value = {
                          legend = false;
                          tooltip = false;
                          viz = true;
                        };
                      }
                    ];
                  }
                ];
                targets = [
                  {
                    expr = "process_max_fds{${nodeFilter}}";
                    legend = "Maximum open file descriptors";
                    step = 240;
                  }
                  {
                    expr = "process_open_fds{${nodeFilter}}";
                    legend = "Open file descriptors";
                    step = 240;
                  }
                ];
              }
              // {id = 207;})
            (mkBarGauge
              {
                x = 20;
                y = 174;
                w = 4;
                h = 10;
                title = "Node Exporter Scrape";
                description = "Shows whether each Node Exporter collector scraped successfully (1 = success, 0 = failure), and whether the textfile collector returned an error.";
                unit = "bool";
                min = null;
                max = null;
                instant = false;
                thresholds = [
                  {
                    value = null;
                    color = "green";
                  }
                  {
                    value = 0;
                    color = "dark-red";
                  }
                  {
                    value = 1;
                    color = "green";
                  }
                ];
                targets = [
                  {
                    expr = "node_scrape_collector_success{${nodeFilter}}";
                    legend = "{{collector}}";
                    step = 240;
                  }
                  {
                    expr = "1 - node_textfile_scrape_error{${nodeFilter}}";
                    legend = "textfile";
                    step = 240;
                  }
                ];
              }
              // {id = 208;})
          ];
        }
      ];
  }
