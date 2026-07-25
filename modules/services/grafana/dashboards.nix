# Custom Grafana dashboards, generated from Nix attrsets (via builtins.toJSON)
# rather than hand-written JSON. Two boards tailored to this fleet's metrics:
# a Fleet Overview status board and a Storage & Hardware board. Community
# dashboards (Node Exporter Full, PostgreSQL, …) are provisioned separately.
{
  lib,
  pkgs,
}: let
  ds = {
    type = "prometheus";
    uid = "prometheus";
  };

  # Three target shapes:
  #   tgt  — range query for timeseries panels (keeps a legend).
  #   stgt — instant query for stat panels (time_series format; a table format
  #          here collapses multi-series into a single cell — the "one giant UP"
  #          bug — and mislabels single values as "Value").
  #   ttgt — instant query in table format for table panels.
  tgt = expr: legend: {
    refId = "A";
    inherit expr;
    legendFormat = legend;
    datasource = ds;
    editorMode = "code";
  };
  stgt = expr:
    (tgt expr "")
    // {
      instant = true;
      range = false;
    };
  ttgt = expr:
    (stgt expr)
    // {
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
    colorMode ? "value",
    mappings ? [],
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
    targets = [(stgt expr)];
    fieldConfig = {
      defaults = {
        inherit unit thresholds mappings;
        color = {mode = "thresholds";};
      };
      overrides = [];
    };
    options = {
      inherit colorMode;
      graphMode = "none";
      textMode = "value";
      justifyMode = "auto";
      reduceOptions = {
        calcs = ["lastNotNull"];
        fields = "";
        values = false;
      };
    };
  };

  # Multi-series stat rendered as a single vertical column: one colour-filled
  # block per series (name + value), tinted by threshold. Unlike mkStat this
  # keeps every series (values=false, no table format) instead of reducing to one.
  mkStatBoard = {
    x,
    y,
    w,
    h,
    title,
    expr,
    legend,
    unit ? "percent",
    thresholds,
    mappings ? [],
  }: {
    type = "stat";
    inherit title;
    gridPos = {inherit x y w h;};
    datasource = ds;
    targets = [
      {
        refId = "A";
        inherit expr;
        legendFormat = legend;
        datasource = ds;
        editorMode = "code";
        instant = true;
        range = false;
      }
    ];
    fieldConfig = {
      defaults = {
        inherit unit thresholds mappings;
        color = {mode = "thresholds";};
      };
      overrides = [];
    };
    options = {
      colorMode = "background";
      graphMode = "none";
      textMode = "value_and_name";
      justifyMode = "auto";
      # horizontal = one full-width bar per service, stacked into rows
      orientation = "horizontal";
      # force legible text — otherwise many rows auto-shrink the font to nothing
      text = {
        titleSize = 13;
        valueSize = 15;
      };
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
    timeFrom ? null, # per-panel relative window (e.g. "24h"), ignores the picker
  }:
    {
      type = "timeseries";
      inherit title;
      gridPos = {inherit x y w h;};
      datasource = ds;
      targets = [(tgt expr legend)];
    }
    // lib.optionalAttrs (timeFrom != null) {inherit timeFrom;}
    // {
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

  # One metric -> a clean two-column table (label + value), dropping the Time and
  # job columns Prometheus tables carry by default. The value column is renamed,
  # unit-formatted, colour-coded by threshold, and optionally value-mapped.
  # Extra labels beyond `instance` (e.g. device) pass through as-is.
  mkMetricTable = {
    x,
    y,
    w ? 12,
    h ? 8,
    title,
    expr,
    labelName, # rename of the source label column -> header
    valueName, # rename of the `Value` column
    labelCol ? "instance", # which label column becomes `labelName`
    dropCols ? [], # extra columns to hide (e.g. the raw `instance` URL)
    labelMappings ? [], # value mappings for the label column (raw value -> display)
    valueUnit ? "short",
    valueAlign ? null, # override the value column's alignment (e.g. "right")
    thresholds ? null,
    mappings ? [],
    cellColor ? false,
    rowColor ? false, # tint the whole row by the value threshold, not just its cell
  }: let
    valueProps =
      [
        {
          id = "unit";
          value = valueUnit;
        }
      ]
      ++ lib.optional (thresholds != null) {
        id = "thresholds";
        value = thresholds;
      }
      ++ lib.optional (mappings != []) {
        id = "mappings";
        value = mappings;
      }
      ++ lib.optional (valueAlign != null) {
        id = "custom.align";
        value = valueAlign;
      }
      ++ lib.optional (cellColor || rowColor) {
        id = "custom.cellOptions";
        value =
          {type = "color-background";}
          // lib.optionalAttrs rowColor {applyToRow = true;};
      };
  in {
    type = "table";
    inherit title;
    gridPos = {inherit x y w h;};
    datasource = ds;
    targets = [(ttgt expr)];
    transformations = [
      {
        id = "organize";
        options = {
          excludeByName =
            {
              Time = true;
              job = true;
            }
            // lib.genAttrs dropCols (_: true);
          renameByName = {
            "${labelCol}" = labelName;
            Value = valueName;
          };
          indexByName = {};
        };
      }
    ];
    fieldConfig = {
      defaults = {custom = {align = "auto";};};
      overrides =
        [
          {
            matcher = {
              id = "byName";
              options = valueName;
            };
            properties = valueProps;
          }
        ]
        ++ lib.optional (labelMappings != []) {
          matcher = {
            id = "byName";
            options = labelName;
          };
          properties = [
            {
              id = "mappings";
              value = labelMappings;
            }
          ];
        };
    };
    options = {
      showHeader = true;
      cellHeight = "sm";
      footer = {show = false;};
    };
  };

  # A "custom" template variable: a static dropdown of values. Used to expose a
  # window selector that drives per-panel timeFrom (e.g. the trend graphs).
  mkCustomVar = {
    name,
    label,
    values,
    default,
  }: {
    inherit name label;
    type = "custom";
    query = lib.concatStringsSep "," values;
    current = {
      selected = true;
      text = default;
      value = default;
    };
    options =
      map (v: {
        text = v;
        value = v;
        selected = v == default;
      })
      values;
    includeAll = false;
    multi = false;
    hide = 0;
    skipUrlSync = false;
  };

  mkDashboard = {
    uid,
    title,
    tags ? ["homelab"],
    panels,
    variables ? [],
    refresh ? "1m",
    from ? "now-6h",
    hideTimePicker ? false,
  }: {
    inherit uid title tags refresh;
    schemaVersion = 39;
    editable = false;
    timezone = "browser";
    time = {
      inherit from;
      to = "now";
    };
    timepicker = {hidden = hideTimePicker;};
    templating = {list = variables;};
    annotations = {list = [];};
    panels = lib.imap1 (i: p: p // {id = i;}) panels;
  };

  greenAtOne = {
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

  # Curated probe-target -> "Product (host it runs on)" map. The host is where
  # the *app* runs (from the machine configs), not the edge that fronts it —
  # e.g. chat/keep/mas are reverse-proxied by commrelay but served by heartbeat.
  # Keys are the exact `instance` label (probe URL / resolver address). Update
  # here if a service moves hosts or a probe URL changes.
  serviceNames = {
    "https://auth.mantannest.com/-/health/live/" = "Authentik (accesscontrolsystem)";
    "https://grafana.mantannest.com/api/health" = "Grafana (heartbeat)";
    "https://headscale.mantannest.com/health" = "Headscale (meshcontrol)";
    "https://headscale.mantannest.com/admin/healthz" = "Headplane (meshcontrol)";
    "https://photos.mantannest.com/api/server/ping" = "Immich (heartbeat)";
    "https://ittools.mantannest.com" = "IT-Tools (heartbeat)";
    "https://jobscraper.mantannest.com/health" = "JobScraper (heartbeat)";
    "https://keep.mantannest.com/api/health" = "Karakeep (heartbeat)";
    "https://loki.mantannest.com/ready" = "Loki (heartbeat)";
    "https://chat.mantannest.com/-/health" = "Matrix / Synapse (heartbeat)";
    "https://mas.chat.mantannest.com/-/health" = "Matrix Auth Service (heartbeat)";
    "https://cloud.mantannest.com/-/health" = "OpenCloud (heartbeat)";
    "https://collabora.cloud.mantannest.com/hosting/discovery" = "Collabora (heartbeat)";
    "https://prometheus.mantannest.com/-/healthy" = "Prometheus (heartbeat)";
    "https://passwords.mantannest.com" = "Vaultwarden (heartbeat)";
    "100.64.0.17:53" = "Primary DNS (caretaker)";
    "100.64.0.22:53" = "Secondary DNS (trialunit)";
  };

  # Curated names -> a `service` label per probe (exact instance match), so the
  # single-column stat board can render them via {{service}}. A chained
  # label_replace: each call wraps the previous, tagging one target's series.
  serviceUptimeExpr = let
    base = "avg_over_time(probe_success[$service_window]) * 100";
    labeled =
      lib.foldl' (
        inner: url: "label_replace(${inner}, \"service\", \"${serviceNames.${url}}\", \"instance\", \"${url}\")"
      )
      base (builtins.attrNames serviceNames);
  in "sort(${labeled})";

  # "up / total" denominators. The push/remote-write model means no live metric
  # enumerates the expected totals, so these are the source of truth:
  #   totalServices — derived from serviceNames, so adding a probe target (which
  #                   you name there anyway) auto-bumps it.
  #   expectedHostList — Alloy agents expected to report; a host that stops
  #                   reporting is flagged DOWN on the health board. Keep in sync
  #                   with the t1_host_silent dead-man threshold in alerting-rules.nix.
  totalServices = builtins.length (builtins.attrNames serviceNames);
  expectedHostList = [
    "accesscontrolsystem"
    "caretaker"
    "commrelay"
    "heartbeat"
    "meshcontrol"
    "watchfulsystem"
  ];
  expectedHosts = builtins.length expectedHostList;

  # A stat cell can't render two live numbers, so the denominator is appended as
  # a custom suffix unit and colour keys off the count: green at full, red if any
  # are missing.
  upTotalSuffix = full: "suffix: / ${toString full}";
  upTotalThresholds = full: {
    mode = "absolute";
    steps = [
      {
        value = null;
        color = "red";
      }
      {
        value = full;
        color = "green";
      }
    ];
  };

  ###########################################################################
  # Host health rollup
  #
  # Each host is reduced to ONE encoded number = level*10 + category, so a single
  # `max by (instance)` picks the worst signal (level dominates; category breaks
  # ties). The number is value-mapped to "<category> <LEVEL>" text and coloured
  # by level band. Hardware signals are per-host-adaptive (a host without a BMC
  # simply never matches the IPMI conditions), and any expected host that stops
  # reporting is surfaced as DOWN.
  ###########################################################################
  hhLevelCode = {
    notice = 1;
    warn = 2;
    crit = 3;
  };
  hhLevelText = {
    notice = "NOTICE";
    warn = "WARN";
    crit = "CRITICAL";
  };
  hhCatText = {
    reboot = "Reboot";
    system = "System";
    thermal = "Thermal";
    power = "Power";
    fans = "Fans";
    ram = "RAM";
    disk = "Disk";
  };
  # Higher category code wins ties within a level (disk/ram most important).
  hhCatCode = {
    reboot = 1;
    system = 2;
    thermal = 3;
    power = 4;
    fans = 5;
    ram = 6;
    disk = 7;
  };
  hhEncode = cat: level: hhLevelCode.${level} * 10 + hhCatCode.${cat};

  # Each condition: a PromQL filter yielding >=1 series exactly where it holds.
  hhConditions = [
    {
      cat = "disk";
      level = "crit";
      e = "smartctl_device_smart_status == 0";
    }
    {
      cat = "disk";
      level = "crit";
      e = "smartctl_device_available_spare < smartctl_device_available_spare_threshold";
    }
    {
      cat = "disk";
      level = "crit";
      e = "zfs_pool_health >= 2";
    }
    {
      cat = "disk";
      level = "warn";
      e = "smartctl_device_percentage_used >= 80";
    }
    {
      cat = "disk";
      level = "warn";
      e = "smartctl_device_media_errors > 0";
    }
    {
      cat = "disk";
      level = "warn";
      e = "zfs_pool_health == 1";
    }
    {
      cat = "disk";
      level = "warn";
      e = "smartctl_device_attribute{attribute_name=~\"Current_Pending_Sector|Offline_Uncorrectable\",attribute_value_type=\"raw\"} > 0";
    }
    {
      cat = "disk";
      level = "warn";
      e = "smartctl_device_attribute{attribute_name=\"Reallocated_Sector_Ct\",attribute_value_type=\"raw\"} >= 50";
    }
    {
      cat = "disk";
      level = "notice";
      e = "smartctl_device_percentage_used >= 60";
    }
    {
      cat = "disk";
      level = "notice";
      e = "smartctl_device_attribute{attribute_name=\"Reallocated_Sector_Ct\",attribute_value_type=\"raw\"} >= 1";
    }
    {
      cat = "disk";
      level = "notice";
      e = "smartctl_device_attribute{attribute_name=\"UDMA_CRC_Error_Count\",attribute_value_type=\"raw\"} >= 1";
    }
    {
      cat = "ram";
      level = "crit";
      e = "increase(node_edac_uncorrectable_errors_total[24h]) > 0";
    }
    {
      cat = "ram";
      level = "warn";
      e = "increase(node_edac_correctable_errors_total[24h]) > 10";
    }
    {
      cat = "ram";
      level = "notice";
      e = "increase(node_edac_correctable_errors_total[24h]) >= 1";
    }
    {
      cat = "thermal";
      level = "crit";
      e = "node_hwmon_temp_celsius >= node_hwmon_temp_crit_celsius";
    }
    {
      cat = "thermal";
      level = "crit";
      e = "ipmi_temperature_state == 2";
    }
    {
      cat = "thermal";
      level = "warn";
      e = "node_hwmon_temp_celsius >= node_hwmon_temp_max_celsius";
    }
    {
      cat = "thermal";
      level = "warn";
      e = "ipmi_temperature_state == 1";
    }
    {
      cat = "thermal";
      level = "notice";
      e = "node_hwmon_temp_celsius >= (node_hwmon_temp_max_celsius - 5)";
    }
    {
      cat = "fans";
      level = "crit";
      e = "ipmi_fan_speed_rpm < 1";
    }
    {
      cat = "power";
      level = "crit";
      e = "ipmi_voltage_state == 2";
    }
    {
      cat = "power";
      level = "notice";
      e = "ipmi_voltage_state == 1";
    }
    {
      cat = "system";
      level = "crit";
      e = "node_systemd_units{state=\"failed\"} > 0";
    }
    {
      cat = "system";
      level = "warn";
      e = "increase(node_vmstat_oom_kill[24h]) > 0";
    }
    {
      cat = "system";
      level = "notice";
      e = "node_timex_sync_status == 0";
    }
    {
      cat = "reboot";
      level = "notice";
      e = "node_reboot_required == 1";
    }
    # A reboot left pending too long escalates: 30d -> WARN, 60d -> CRITICAL.
    {
      cat = "reboot";
      level = "warn";
      e = "node_reboot_required == 1 and (time() - node_reboot_required_since_seconds) >= 2592000";
    }
    {
      cat = "reboot";
      level = "crit";
      e = "node_reboot_required == 1 and (time() - node_reboot_required_since_seconds) >= 5184000";
    }
  ];

  # The rollup query: baseline 0 for every reporting host, one encoded term per
  # condition (tagged with a distinct `cond` label so `or` doesn't drop equal
  # label sets), and a DOWN term for expected hosts that aren't reporting.
  hostHealthExpr = let
    reporting = "group by (instance) (alloy_build_info)";
    tag = id: body: "label_replace(${body}, \"cond\", \"${id}\", \"\", \"\")";
    baseline = tag "base" "0 * ${reporting}";
    contribs =
      lib.imap0 (
        i: c:
          tag "c${toString i}" "clamp_max(count by (instance) (${c.e}), 1) * ${toString (hhEncode c.cat c.level)}"
      )
      hhConditions;
    expectedVec = lib.concatStringsSep " or " (map (h: "label_replace(vector(1), \"instance\", \"${h}\", \"\", \"\")") expectedHostList);
    down = tag "down" "40 * ((${expectedVec}) unless ${reporting})";
    terms = [baseline] ++ contribs ++ [down];
  in "max by (instance) (${lib.concatStringsSep " or " terms})";

  # Value mappings: encoded number -> "<category> <LEVEL>" text, plus OK/DOWN.
  hostHealthMappings = let
    combos = lib.unique (map (c: {inherit (c) cat level;}) hhConditions);
    comboEntries =
      map (c: {
        name = toString (hhEncode c.cat c.level);
        text = "${hhCatText.${c.cat}} ${hhLevelText.${c.level}}";
      })
      combos;
    entries =
      [
        {
          name = "0";
          text = "OK";
        }
        {
          name = "40";
          text = "DOWN";
        }
      ]
      ++ comboEntries;
  in [
    {
      type = "value";
      options = builtins.listToAttrs (map (e: {
          inherit (e) name;
          value = {inherit (e) text;};
        })
        entries);
    }
  ];

  # Colour by level band: OK green, NOTICE blue, WARN yellow, CRITICAL red, DOWN dark-red.
  hostHealthThresholds = {
    mode = "absolute";
    steps = [
      {
        value = null;
        color = "green";
      }
      {
        value = 10;
        color = "blue";
      }
      {
        value = 20;
        color = "yellow";
      }
      {
        value = 30;
        color = "red";
      }
      {
        value = 40;
        color = "dark-red";
      }
    ];
  };

  ###########################################################################
  # Fleet Overview — status board
  ###########################################################################
  fleetOverview = mkDashboard {
    uid = "homelab-fleet";
    title = "Fleet Overview";
    refresh = "30s";
    hideTimePicker = true;
    # Dropdown driving the trend panels' window (they use timeFrom = $trend_window),
    # so CPU/mem/disk can be viewed at 6h…30d without a global time picker.
    variables = [
      (mkCustomVar {
        name = "trend_window";
        label = "Trend window";
        values = ["1h" "6h" "12h" "24h" "2d" "7d" "30d"];
        default = "6h";
      })
      (mkCustomVar {
        name = "service_window";
        label = "Service uptime window";
        values = ["1h" "6h" "24h" "7d" "30d" "1y"];
        default = "7d";
      })
    ];
    panels = [
      # --- headline stats -------------------------------------------------
      (mkStat {
        x = 0;
        y = 0;
        w = 8;
        title = "Hosts reporting";
        expr = "count(group by (instance) (alloy_build_info))";
        unit = upTotalSuffix expectedHosts;
        colorMode = "background";
        thresholds = upTotalThresholds expectedHosts;
      })
      (mkStat {
        x = 8;
        y = 0;
        w = 8;
        title = "Services up";
        expr = "sum(probe_success)";
        unit = upTotalSuffix totalServices;
        colorMode = "background";
        thresholds = upTotalThresholds totalServices;
      })
      (mkStat {
        x = 16;
        y = 0;
        w = 8;
        title = "Alert status";
        expr = "sum(grafana_alerting_alerts{state=\"alerting\"}) or vector(0)";
        colorMode = "background";
        thresholds = greenAtOne;
        # 0 -> "All clear" (green); any firing count shows the number (red).
        mappings = [
          {
            type = "value";
            options = {
              "0" = {
                text = "All clear";
                index = 0;
              };
            };
          }
        ];
      })

      # --- status boards --------------------------------------------------
      (mkStatBoard {
        x = 0;
        y = 4;
        w = 8;
        h = 18;
        title = "Host health";
        expr = hostHealthExpr;
        legend = "{{instance}}";
        unit = "none";
        thresholds = hostHealthThresholds;
        mappings = hostHealthMappings;
      })
      (mkStatBoard {
        x = 8;
        y = 4;
        w = 16;
        h = 18;
        title = "Service uptime ($service_window availability)";
        # Availability over the $service_window dropdown, one colour-filled row
        # per service. Names come from the serviceNames map, folded into a
        # `service` label (see serviceUptimeExpr above). The window lives in the
        # PromQL range selector, which Grafana interpolates per selection.
        expr = serviceUptimeExpr;
        legend = "{{service}}";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "red";
            }
            {
              value = 95;
              color = "yellow";
            }
            {
              value = 99.9;
              color = "green";
            }
          ];
        };
      })

      # --- resource trends ------------------------------------------------
      (mkTimeseries {
        x = 0;
        y = 22;
        title = "CPU busy % (per host)";
        expr = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 8;
        y = 22;
        title = "Memory used % (per host)";
        expr = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 16;
        y = 22;
        title = "Fullest filesystem % (per host)";
        expr = "max by (instance) (100 * (1 - node_filesystem_avail_bytes{fstype!~\"tmpfs|ramfs|overlay|squashfs|efivarfs|nsfs|devtmpfs|autofs|fuse.*\"} / node_filesystem_size_bytes))";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })

      # --- backups & certs ------------------------------------------------
      (mkMetricTable {
        x = 0;
        y = 30;
        w = 12;
        title = "Backups — hours since last success";
        expr = "sort_desc((time() - homelab_backup_last_success_timestamp_seconds) / 3600)";
        labelName = "Host";
        valueName = "Hours ago";
        valueUnit = "h";
        cellColor = true;
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "green";
            }
            {
              value = 26;
              color = "red";
            }
          ];
        };
      })
      (mkMetricTable {
        x = 12;
        y = 30;
        w = 12;
        title = "TLS certificate expiry";
        expr = "sort((probe_ssl_earliest_cert_expiry - time()) / 86400)";
        labelName = "URL";
        valueName = "Days to expire";
        valueUnit = "d";
        cellColor = true;
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
  };
in {
  fleet = pkgs.writeText "homelab-fleet.json" (builtins.toJSON fleetOverview);
  storage = pkgs.writeText "homelab-storage-hw.json" (builtins.toJSON storageHardware);
}
