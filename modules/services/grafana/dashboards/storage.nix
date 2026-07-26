# Storage & Hardware — ZFS, SMART, and IPMI detail. Unlike Fleet Overview this
# uses the normal time picker; it's for digging into a specific hardware
# signal over a chosen window, not a fixed-window status board.
{
  lib,
  helpers,
}: let
  inherit (helpers) mkStat mkTimeseries mkMetricTable mkDashboard greenAtOne;
in
  mkDashboard {
    uid = "homelab-storage-hw";
    title = "Storage & Hardware";
    panels = [
      (mkStat {
        x = 0;
        y = 0;
        w = 8;
        title = "ZFS pools not ONLINE";
        expr = "count(zfs_pool_health > 0) or vector(0)";
        colorMode = "background";
        thresholds = greenAtOne;
      })
      (mkStat {
        x = 8;
        y = 0;
        w = 8;
        title = "Disks SMART-failing";
        expr = "count(smartctl_device_smart_status < 1) or vector(0)";
        colorMode = "background";
        thresholds = greenAtOne;
      })
      (mkStat {
        x = 16;
        y = 0;
        w = 8;
        title = "ZFS ARC hit ratio";
        expr = "sum(rate(node_zfs_arc_hits[5m])) / (sum(rate(node_zfs_arc_hits[5m])) + sum(rate(node_zfs_arc_misses[5m])))";
        unit = "percentunit";
      })
      (mkTimeseries {
        x = 0;
        y = 4;
        w = 12;
        title = "Disk temperatures (SMART)";
        expr = "smartctl_device_temperature{temperature_type=\"current\"}";
        unit = "celsius";
        legend = "{{instance}} {{device}}";
      })
      (mkTimeseries {
        x = 12;
        y = 4;
        w = 12;
        title = "IPMI temperatures";
        expr = "ipmi_temperature_celsius";
        unit = "celsius";
        legend = "{{instance}} {{name}}";
      })
      (mkTimeseries {
        x = 0;
        y = 12;
        w = 12;
        title = "IPMI fan speeds";
        expr = "ipmi_fan_speed_rpm";
        unit = "rotrpm";
        legend = "{{instance}} {{name}}";
        min = 0;
      })
      (mkMetricTable {
        x = 12;
        y = 12;
        w = 12;
        title = "SSD wear";
        expr = "smartctl_device_percentage_used";
        labelName = "Host";
        valueName = "Wear";
        valueUnit = "percent";
        cellColor = true;
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "green";
            }
            {
              value = 80;
              color = "yellow";
            }
            {
              value = 90;
              color = "red";
            }
          ];
        };
      })
    ];
  }
