# Custom Grafana dashboards, generated from Nix attrsets (via builtins.toJSON)
# rather than hand-written JSON. Two boards tailored to this fleet's metrics:
# a Fleet Overview single-pane and a Storage & Hardware board. Community
# dashboards (Node Exporter Full, PostgreSQL, …) are provisioned separately.
{
  lib,
  pkgs,
}: let
  ds = {
    type = "prometheus";
    uid = "prometheus";
  };

  # range target (timeseries) and instant target (stat/table)
  tgt = expr: legend: {
    refId = "A";
    inherit expr;
    legendFormat = legend;
    datasource = ds;
    editorMode = "code";
  };
  itgt = expr: legend:
    (tgt expr legend)
    // {
      instant = true;
      range = false;
      format = "table";
    };

  mkStat = {
    x,
    y,
    w ? 6,
    h ? 4,
    title,
    expr,
    unit ? "none",
    legend ? "",
    mappings ? [],
    colorMode ? "value",
    thresholds ? {
      mode = "absolute";
      steps = [
        {
          value = null;
          color = "text";
        }
      ];
    },
  }: {
    type = "stat";
    inherit title;
    gridPos = {inherit x y w h;};
    datasource = ds;
    targets = [(itgt expr legend)];
    fieldConfig = {
      defaults = {
        inherit unit mappings thresholds;
        color = {mode = "thresholds";};
      };
      overrides = [];
    };
    options = {
      inherit colorMode;
      graphMode = "none";
      textMode = "value_and_name";
      justifyMode = "auto";
      reduceOptions = {
        calcs = ["lastNotNull"];
        fields = "";
        values = false;
      };
    };
  };

  mkTimeseries = {
    x,
    y,
    w ? 8,
    h ? 8,
    title,
    expr,
    unit ? "short",
    legend ? "{{instance}}",
    min ? null,
    max ? null,
  }: {
    type = "timeseries";
    inherit title;
    gridPos = {inherit x y w h;};
    datasource = ds;
    targets = [(tgt expr legend)];
    fieldConfig = {
      defaults =
        {
          inherit unit;
          custom = {
            fillOpacity = 10;
            showPoints = "never";
            lineWidth = 1;
          };
        }
        // lib.optionalAttrs (min != null) {inherit min;}
        // lib.optionalAttrs (max != null) {inherit max;};
      overrides = [];
    };
    options = {
      legend = {
        displayMode = "list";
        placement = "bottom";
        showLegend = true;
      };
      tooltip = {mode = "multi";};
    };
  };

  mkTable = {
    x,
    y,
    w ? 12,
    h ? 8,
    title,
    targets,
    overrides ? [],
  }: {
    type = "table";
    inherit title targets;
    gridPos = {inherit x y w h;};
    datasource = ds;
    fieldConfig = {
      defaults = {custom = {align = "auto";};};
      inherit overrides;
    };
    options = {
      showHeader = true;
      cellHeight = "sm";
    };
    transformations = [
      {
        id = "merge";
        options = {};
      }
    ];
  };

  # value mapping: 0 -> DOWN(red), 1 -> UP(green)
  upDownMap = [
    {
      type = "value";
      options = {
        "0" = {
          text = "DOWN";
          color = "red";
          index = 0;
        };
        "1" = {
          text = "UP";
          color = "green";
          index = 1;
        };
      };
    }
  ];

  mkDashboard = {
    uid,
    title,
    tags ? ["homelab"],
    panels,
    refresh ? "1m",
    from ? "now-6h",
  }: {
    inherit uid title tags refresh;
    schemaVersion = 39;
    editable = false;
    timezone = "browser";
    time = {
      inherit from;
      to = "now";
    };
    templating = {list = [];};
    annotations = {list = [];};
    panels = lib.imap1 (i: p: p // {id = i;}) panels;
  };

  ###########################################################################
  # Fleet Overview
  ###########################################################################
  fleetOverview = mkDashboard {
    uid = "homelab-fleet";
    title = "Fleet Overview";
    panels = [
      (mkStat {
        x = 0;
        y = 0;
        title = "Hosts reporting";
        expr = "count(group by (instance) (alloy_build_info))";
      })
      (mkStat {
        x = 6;
        y = 0;
        title = "Services up";
        expr = "sum(probe_success)";
      })
      (mkStat {
        x = 12;
        y = 0;
        title = "Firing alerts";
        expr = "sum(grafana_alerting_alerts{state=\"alerting\"}) or vector(0)";
        colorMode = "background";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "green";
            }
            {
              value = 1;
              color = "red";
            }
          ];
        };
      })
      (mkStat {
        x = 18;
        y = 0;
        title = "Nearest cert expiry (days)";
        expr = "min(probe_ssl_earliest_cert_expiry - time()) / 86400";
        unit = "d";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "red";
            }
            {
              value = 14;
              color = "yellow";
            }
            {
              value = 30;
              color = "green";
            }
          ];
        };
      })
      (mkStat {
        x = 0;
        y = 4;
        w = 24;
        h = 6;
        title = "Service availability";
        expr = "probe_success";
        legend = "{{instance}}";
        mappings = upDownMap;
        colorMode = "background";
      })
      (mkTimeseries {
        x = 0;
        y = 10;
        title = "CPU busy % (per host)";
        expr = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)";
        unit = "percent";
        max = 100;
        min = 0;
      })
      (mkTimeseries {
        x = 8;
        y = 10;
        title = "Memory used % (per host)";
        expr = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)";
        unit = "percent";
        max = 100;
        min = 0;
      })
      (mkTimeseries {
        x = 16;
        y = 10;
        title = "Fullest filesystem % (per host)";
        expr = "max by (instance) (100 * (1 - node_filesystem_avail_bytes{fstype!~\"tmpfs|ramfs|overlay|squashfs|efivarfs|nsfs|devtmpfs|autofs|fuse.*\"} / node_filesystem_size_bytes))";
        unit = "percent";
        max = 100;
        min = 0;
      })
      (mkTable {
        x = 0;
        y = 18;
        title = "Backups (last-success age & status)";
        targets = [
          (itgt "homelab_backup_success" "")
          (itgt "(time() - homelab_backup_last_success_timestamp_seconds) / 3600" "")
        ];
      })
      (mkTable {
        x = 12;
        y = 18;
        title = "TLS certificate expiry (days)";
        targets = [
          (itgt "sort((probe_ssl_earliest_cert_expiry - time()) / 86400)" "")
        ];
      })
    ];
  };

  ###########################################################################
  # Storage & Hardware
  ###########################################################################
  storageHardware = mkDashboard {
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
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "green";
            }
            {
              value = 1;
              color = "red";
            }
          ];
        };
      })
      (mkStat {
        x = 8;
        y = 0;
        w = 8;
        title = "Disks SMART-failing";
        expr = "count(smartctl_device_smart_status < 1) or vector(0)";
        colorMode = "background";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "green";
            }
            {
              value = 1;
              color = "red";
            }
          ];
        };
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
      (mkTable {
        x = 12;
        y = 12;
        w = 12;
        title = "SSD wear (percentage used)";
        targets = [
          (itgt "smartctl_device_percentage_used" "")
        ];
      })
    ];
  };
in {
  fleet = pkgs.writeText "homelab-fleet.json" (builtins.toJSON fleetOverview);
  storage = pkgs.writeText "homelab-storage-hw.json" (builtins.toJSON storageHardware);
}
