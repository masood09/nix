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

  # MemAvailable-based "used %" (the naive `1 - MemAvailable/MemTotal`) treats
  # ZFS ARC as fully used memory, since ARC lives outside the reclaimable page
  # cache MemAvailable accounts for — on an ARC-heavy host that reads as ~85%
  # used even when htop shows single digits. Match htop's own accounting
  # instead: exclude buffers, reclaimable slab, and ARC (all effectively
  # freeable cache) from "used", the same way htop's LinuxMachine.c does for
  # ZFS-aware systems. Falls back to 0 ARC on non-ZFS hosts (caretaker et al.)
  # via the `or on(instance)` pattern, so one expression covers the whole fleet.
  memoryUsedExpr = let
    cachedMem = "(node_memory_Cached_bytes + node_memory_SReclaimable_bytes - node_memory_Shmem_bytes)";
    arcOrZero = "(node_zfs_arc_size or on(instance) (0 * node_memory_MemTotal_bytes))";
    usedBytes = "(node_memory_MemTotal_bytes - node_memory_MemFree_bytes - node_memory_Buffers_bytes - ${cachedMem} - ${arcOrZero})";
  in "100 * ${usedBytes} / node_memory_MemTotal_bytes";

  # Per-pool ZFS capacity (rpool/fpool/dpool on heartbeat, rpool-only on the
  # single-pool hosts), not per-mountpoint filesystem stats: every
  # impermanence-backed service dataset shares the pool's free space and
  # mounts separately, so a per-mountpoint view balloons to 100+ near-
  # duplicate rows on heartbeat alone without saying anything a per-pool
  # number doesn't. Falls back to root-filesystem % on non-ZFS hosts
  # (caretaker now; sonic/usul too, if they start reporting) via `unless`,
  # so one expression covers the whole fleet without per-host branching.
  diskUsedExpr = let
    zfsPools = "100 * zfs_pool_allocated_bytes / zfs_pool_size_bytes";
    nonZfsRoot = "label_replace(100 * (1 - node_filesystem_avail_bytes{mountpoint=\"/nix\"} / node_filesystem_size_bytes{mountpoint=\"/nix\"}) unless on(instance) (zfs_pool_size_bytes), \"pool\", \"root (/nix)\", \"\", \"\")";
  in "${zfsPools} or ${nonZfsRoot}";

  # Disk I/O throughput broken out by device class, not just summed per host —
  # an HDD, a SATA SSD, and an NVMe drive have wildly different baselines, so
  # a single blended number per host hides which device is actually busy.
  # node_disk_ata_rotation_rate_rpm classifies ATA devices (>0 = HDD, 0 = SATA
  # SSD); NVMe devices are matched by name since they aren't ATA and never
  # report that metric; anything left (KVM/cloud virtio block volumes, e.g.
  # meshcontrol's OCI BlockVolume) falls into "virtual/other". Device-mapper
  # nodes (dm-*, e.g. caretaker's LUKS layer) are excluded everywhere — they
  # sit on top of an already-counted physical device, so including them
  # double-counts the same I/O twice.
  diskIoByTypeExpr = let
    ioRate = deviceFilter: "sum by (instance, device) (rate(node_disk_read_bytes_total${deviceFilter}[5m]) + rate(node_disk_written_bytes_total${deviceFilter}[5m]))";
    tag = type: body: "label_replace(${body}, \"type\", \"${type}\", \"\", \"\")";
    ioRateAll = ioRate "";
    nvme = tag "nvme" (ioRate "{device=~\"nvme.*\"}");
    hdd = tag "hdd" "${ioRateAll} and on(instance, device) (node_disk_ata_rotation_rate_rpm > 0)";
    ssd = tag "ssd" "${ioRateAll} and on(instance, device) (node_disk_ata_rotation_rate_rpm == 0)";
    other = tag "virtual/other" "${ioRate "{device!~\"nvme.*|zram.*|dm-.*\"}"} unless on(instance, device) (node_disk_ata_rotation_rate_rpm)";
  in "sum by (instance, type) (${nvme} or ${hdd} or ${ssd} or ${other})";

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

  # Colour by level band: OK = no colour, NOTICE light-orange, WARN orange, CRITICAL red,
  # DOWN semi-dark-purple (distinct hue — "no data", not a more severe red).
  # NOTICE/WARN stay within one hue family rather than switching to yellow:
  # yellow is the highest-luminance hue humans perceive, so a plain "yellow"
  # swatch reads as louder than "orange" regardless of which is meant to be
  # more severe — varying intensity within one hue is the reliable escalation
  # cue, switching hues isn't.
  hostHealthThresholds = {
    mode = "absolute";
    steps = [
      {
        value = null;
        color = "transparent";
      }
      {
        value = 10;
        color = "light-orange";
      }
      {
        value = 20;
        color = "orange";
      }
      {
        value = 30;
        color = "red";
      }
      {
        value = 40;
        # Distinct from the red-family severities: DOWN means "no data at
        # all" (host stopped reporting), not "we detected a problem" — a
        # different kind of signal, not a more severe one.
        color = "semi-dark-purple";
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
    # so CPU/mem/disk can be viewed at 5m…30d without a global time picker.
    variables = [
      (mkCustomVar {
        name = "trend_window";
        label = "Trend window";
        values = ["5m" "15m" "30m" "1h" "6h" "12h" "24h" "2d" "7d" "30d"];
        default = "15m";
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
        description = "Count of hosts currently sending metrics, out of the expected fleet total. Green means every expected host is reporting; red means at least one has gone silent.";
        expr = "count(group by (instance) (alloy_build_info))";
        unit = upTotalSuffix expectedHosts;
        colorMode = "background_solid";
        thresholds = upTotalThresholds expectedHosts;
      })
      (mkStat {
        x = 8;
        y = 0;
        w = 8;
        title = "Services up";
        description = "Count of monitored services currently passing their health probe, out of the total tracked (see serviceNames in fleet.nix). Green means all are up; red means at least one is down.";
        expr = "sum(probe_success)";
        unit = upTotalSuffix totalServices;
        colorMode = "background_solid";
        thresholds = upTotalThresholds totalServices;
      })
      (mkStat {
        x = 16;
        y = 0;
        w = 8;
        title = "Alert status";
        description = "Number of currently-firing Grafana alert rules. Shows \"All clear\" in green when nothing is alerting; shows the firing count in red otherwise.";
        expr = "sum(grafana_alerting_alerts{state=\"alerting\"}) or vector(0)";
        colorMode = "background_solid";
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
        w = 24;
        h = 8;
        title = "Host health";
        description = "Worst-case signal per host across disk, RAM, thermal, power, fans, system, and pending-reboot checks (see hhConditions in fleet.nix). No fill = nothing wrong. NOTICE/WARN/CRITICAL (light-orange/orange/red) name the worst active issue and its category — e.g. \"Disk WARN\". DOWN (purple) means the host has stopped reporting entirely — a different kind of signal than a detected problem. This collapses everything to one number per host; expand a specific category on the disk/memory panels below, or check Storage & Hardware for raw SMART/IPMI detail.";
        expr = hostHealthExpr;
        legend = "{{instance}}";
        unit = "none";
        thresholds = hostHealthThresholds;
        mappings = hostHealthMappings;
      })
      (mkStatBoard {
        x = 0;
        y = 12;
        w = 24;
        h = 18;
        title = "Service uptime ($service_window availability)";
        # Availability over the $service_window dropdown, one colour-filled row
        # per service. Names come from the serviceNames map, folded into a
        # `service` label (see serviceUptimeExpr above). The window lives in the
        # PromQL range selector, which Grafana interpolates per selection.
        description = "Average blackbox-probe availability of each monitored service over the $service_window dropdown at the top of the dashboard — not the (hidden) global time picker. No fill ≥ 99.9% (under ~10 min downtime/week); NOTICE ≥ 99.5% (up to ~50 min/week); WARN ≥ 95% (up to ~8.4 hours/week); CRITICAL below that. Change the dropdown to see a shorter or longer availability window.";
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
              color = "orange";
            }
            {
              value = 99.5;
              color = "light-orange";
            }
            {
              value = 99.9;
              color = "transparent";
            }
          ];
        };
      })

      # --- resource trends ------------------------------------------------
      (mkTimeseries {
        x = 0;
        y = 38;
        title = "CPU busy % (per host)";
        description = "Average CPU utilization per host (100% minus idle time, averaged across all cores) over the $trend_window dropdown below.";
        expr = "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 0;
        y = 46;
        w = 8;
        title = "Memory used % (per host)";
        description = "Memory used per the kernel's own reclaim-aware estimate (1 - MemAvailable/MemTotal) — a conservative, capacity-planning-oriented number. It treats ZFS ARC as unavailable, so ARC-heavy hosts (see ZFS ARC usage % below) read much higher here than in the \"htop view\" panel alongside it. Use this one to judge real OOM risk / headroom; use the htop view for an intuitive at-a-glance read.";
        expr = "100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 16;
        y = 38;
        title = "System load % (per host)";
        # Same normalization Node Exporter Full uses for its "Sys Load" gauge:
        # load1 as a % of core count (100% = load matches core count), rather
        # than the raw, unbounded load1 number.
        description = "1-minute load average as a % of CPU core count (100% = load matches core count) — the same normalization Node Exporter Full's \"Sys Load\" gauge uses, so it's comparable across hosts with different core counts. Unlike the other panels in this row, it can legitimately exceed 100% (more work queued than cores available).";
        expr = "100 * node_load1 / on(instance) count by (instance) (count by (instance, cpu) (node_cpu_seconds_total))";
        unit = "percent";
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 8;
        y = 38;
        title = "Memory used % — htop view (per host)";
        # MemAvailable-based "used %" above treats ZFS ARC as fully used,
        # since ARC isn't the reclaimable page cache MemAvailable accounts
        # for — reads ~85% on an ARC-heavy host even when htop shows single
        # digits. This matches htop's own accounting instead (excludes
        # buffers, reclaimable slab, and ARC from "used"); see memoryUsedExpr.
        description = "Memory used matching htop's own accounting: excludes buffers, reclaimable slab, and ZFS ARC from \"used\", since htop treats all of that as effectively free. Reads much lower than \"Memory used % (per host)\" on ARC-heavy hosts — that gap is exactly what the ZFS ARC usage % panel alongside it shows. Use this one for an intuitive read; use the MemAvailable-based panel for real headroom/OOM-risk judgment.";
        expr = memoryUsedExpr;
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 8;
        y = 46;
        w = 8;
        title = "ZFS ARC usage % (per host)";
        # How much of total RAM the ARC currently holds — the gap between
        # the two memory panels above, made explicit. 0 on non-ZFS hosts.
        description = "Share of total RAM currently held by the ZFS Adaptive Replacement Cache (ARC). Explains the gap between the two memory panels to the left: the MemAvailable-based one counts this as used, the htop-view one counts it as free. Reads 0% on non-ZFS hosts (caretaker, and sonic/usul if they start reporting).";
        expr = "100 * (node_zfs_arc_size or on(instance) (0 * node_memory_MemTotal_bytes)) / node_memory_MemTotal_bytes";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 16;
        y = 46;
        w = 8;
        title = "Swap used % (per host)";
        description = "Percentage of configured swap space currently in use per host. Occasional low usage is normal; sustained non-zero swap under regular (non-spiky) load usually indicates real memory pressure.";
        expr = "100 * (1 - node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })

      # --- disk ------------------------------------------------------------
      (mkTimeseries {
        x = 0;
        y = 54;
        w = 8;
        title = "Disk used % (per host, per pool)";
        description = "ZFS pool capacity (allocated/size) per pool, e.g. heartbeat's rpool/fpool/dpool shown as separate lines rather than blended into one number — every impermanence-backed service dataset shares its pool's free space, so a per-mountpoint view would balloon into 100+ near-duplicate rows. Non-ZFS hosts (caretaker; sonic/usul if they start reporting) fall back to root-filesystem usage, labeled \"root (/nix)\".";
        expr = diskUsedExpr;
        legend = "{{instance}} ({{pool}})";
        unit = "percent";
        max = 100;
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 8;
        y = 54;
        w = 8;
        title = "Disk I/O throughput by type (per host)";
        description = "Combined read+write throughput per host, split by device class (nvme/hdd/ssd/virtual-other for cloud/KVM block volumes) since baselines differ wildly by type — an HDD near its ceiling looks nothing like an idle NVMe. A 5-minute rolling average, so short bursts are smoothed rather than shown as sharp peaks. Best used to spot which host and device is actively busy right now (a backup, scrub, big transfer), not to judge against theoretical hardware maximums — quiet numbers are normal and expected, since ZFS ARC absorbs most reads before they reach disk.";
        expr = diskIoByTypeExpr;
        legend = "{{instance}} ({{type}})";
        unit = "Bps";
        min = 0;
        timeFrom = "$trend_window";
      })
      (mkTimeseries {
        x = 16;
        y = 54;
        w = 8;
        title = "Disk I/O wait % (per host)";
        description = "CPU time spent blocked waiting on any disk I/O, per host. Host-level only — iowait has no per-disk breakdown, unlike the throughput panel next to it. Rising alongside high throughput suggests the disk is actually a bottleneck right now; low iowait during high throughput means the disk is keeping up fine.";
        expr = "avg by (instance) (rate(node_cpu_seconds_total{mode=\"iowait\"}[5m])) * 100";
        unit = "percent";
        min = 0;
        timeFrom = "$trend_window";
      })

      # --- backups & certs ------------------------------------------------
      (mkStatBoard {
        x = 0;
        y = 30;
        w = 24;
        h = 6;
        title = "Backups";
        description = "Whether each host's backups are healthy, not when they last ran. OK = last success within 26 hours (enough slack over a 24h daily cadence for normal run-time variance); MISSED = a backup has actually been missed.";
        expr = "sort_desc((time() - homelab_backup_last_success_timestamp_seconds) / 3600)";
        legend = "{{instance}}";
        unit = "none";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "transparent";
            }
            {
              value = 26;
              color = "red";
            }
          ];
        };
        mappings = [
          {
            type = "range";
            options = {
              from = 0;
              to = 26;
              result = {text = "OK";};
            };
          }
          {
            type = "range";
            options = {
              from = 26;
              to = 999999;
              result = {text = "MISSED";};
            };
          }
        ];
      })
      (mkStatBoard {
        x = 0;
        y = 62;
        w = 24;
        h = 16;
        title = "TLS certificate expiry";
        # unit = "suffix: days" (a literal string appended after the number)
        # rather than Grafana's "d" time unit, which auto-scales to weeks for
        # larger values — the point is a plain day count, not adaptive
        # duration formatting.
        description = "Days remaining before each monitored certificate expires. CRITICAL under 7 days (renewal has clearly failed), WARN under 14 (should have auto-renewed already), NOTICE under 30 (approaching the typical ACME renewal window), no fill beyond.";
        # Strip scheme + path from the probe URL, leaving just the domain —
        # the path doesn't matter for a cert (it's issued per-domain).
        expr = "label_replace(sort((probe_ssl_earliest_cert_expiry - time()) / 86400), \"domain\", \"$1\", \"instance\", \"https?://([^/]+).*\")";
        legend = "{{domain}}";
        unit = "suffix: days";
        thresholds = {
          mode = "absolute";
          steps = [
            {
              value = null;
              color = "red";
            }
            {
              value = 7;
              color = "orange";
            }
            {
              value = 14;
              color = "light-orange";
            }
            {
              value = 30;
              color = "transparent";
            }
          ];
        };
      })
    ];
  }
