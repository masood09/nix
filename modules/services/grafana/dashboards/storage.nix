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
        description = "Count of ZFS pools fleet-wide not in a healthy ONLINE state (zfs_pool_health > 0 — DEGRADED, FAULTED, etc.). Should always read 0.";
        expr = "count(zfs_pool_health > 0) or vector(0)";
        colorMode = "background";
        thresholds = greenAtOne;
      })
      (mkStat {
        x = 8;
        y = 0;
        w = 8;
        title = "Disks SMART-failing";
        description = "Count of disks fleet-wide whose SMART self-assessment reports failing. Should always read 0 — a disk that shows up here should be replaced soon, not just watched.";
        expr = "count(smartctl_device_smart_status < 1) or vector(0)";
        colorMode = "background";
        thresholds = greenAtOne;
      })
      (mkStat {
        x = 16;
        y = 0;
        w = 8;
        title = "ZFS ARC hit ratio";
        description = "Fraction of ZFS reads served from the in-memory ARC cache rather than physical disk, fleet-wide. Higher is better; a sustained drop can mean the working set no longer fits in ARC, which precedes disk read pressure — cross-check against Fleet Overview's Disk I/O panels if this trends down.";
        expr = "sum(rate(node_zfs_arc_hits[5m])) / (sum(rate(node_zfs_arc_hits[5m])) + sum(rate(node_zfs_arc_misses[5m])))";
        unit = "percentunit";
      })
      (mkTimeseries {
        x = 0;
        y = 4;
        w = 12;
        title = "Disk temperatures (SMART)";
        description = "Per-disk temperature as reported by SMART, one line per (host, device). Sustained readings above the drive's rated operating range shorten its lifespan — check the manufacturer's datasheet for the specific threshold, since it varies by model.";
        expr = "smartctl_device_temperature{temperature_type=\"current\"}";
        unit = "celsius";
        legend = "{{instance}} {{device}}";
      })
      (mkTimeseries {
        x = 12;
        y = 4;
        w = 12;
        title = "IPMI temperatures";
        description = "Per-sensor temperature reported via IPMI (CPU, motherboard, ambient, etc.), across BMC-equipped hosts only — hosts without a BMC simply show nothing here.";
        expr = "ipmi_temperature_celsius";
        unit = "celsius";
        legend = "{{instance}} {{name}}";
      })
      (mkTimeseries {
        x = 0;
        y = 12;
        w = 12;
        title = "IPMI fan speeds";
        description = "Per-fan RPM reported via IPMI, across BMC-equipped hosts. A fan reading at or near 0 while the host is running usually means a failed fan, not an idle one.";
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
        description = "SMART-reported percentage of a SATA/NVMe SSD's rated write endurance used. Approaching 100% means the drive is nearing its wear-out point and should be planned for replacement; this metric only applies to SSDs, not spinning HDDs.";
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
