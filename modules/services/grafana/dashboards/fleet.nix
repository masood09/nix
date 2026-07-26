# Fleet Overview — a fleet status board, not a time-series exploration tool.
# Service availability and host health are pinned to their own dropdown
# windows ($service_window, $trend_window) rather than the global time
# picker (hidden), so the board always shows "what's the state right now",
# regardless of when it's opened.
{
  lib,
  helpers,
}: let
  inherit (helpers) mkStat mkStatBoard mkTimeseries mkMetricTable mkDashboard mkCustomVar greenAtOne upTotalSuffix upTotalThresholds;

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
in
  mkDashboard {
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
  }
