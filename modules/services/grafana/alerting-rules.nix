# Grafana-managed alert rules (provisioned). Each rule is a Prometheus range
# query (A) -> reduce last (B) -> threshold (C), the model the Grafana UI
# generates, so it evaluates one alert instance per series. The `severity` label
# drives routing to the Discord contact points (see default.nix policies).
{lib}: let
  promUid = "prometheus";

  mkAlert = {
    uid,
    title,
    expr,
    op, # threshold operator: "lt" | "gt"
    threshold,
    severity ? "critical",
    pending ? "5m",
    summary,
    description ? "",
    noData ? "OK", # "OK" = don't fire on missing data; "Alerting" = fire
    # One evaluation at "now" instead of a 10-minute range: for expressions
    # that already look far back themselves (last_over_time over days), where
    # repeating that at every 30 s step would be wasted work.
    instant ? false,
  }: {
    inherit uid title;
    condition = "C";
    for = pending;
    labels = {inherit severity;};
    annotations = {inherit summary description;};
    noDataState = noData;
    execErrState = "Error";
    data = [
      {
        refId = "A";
        relativeTimeRange = {
          from = 600;
          to = 0;
        };
        datasourceUid = promUid;
        model = {
          refId = "A";
          inherit expr instant;
          range = !instant;
          intervalMs = 30000;
          maxDataPoints = 43200;
          datasource = {
            type = "prometheus";
            uid = promUid;
          };
        };
      }
      {
        refId = "B";
        relativeTimeRange = {
          from = 600;
          to = 0;
        };
        datasourceUid = "__expr__";
        model = {
          refId = "B";
          type = "reduce";
          reducer = "last";
          expression = "A";
          datasource = {
            type = "__expr__";
            uid = "__expr__";
          };
        };
      }
      {
        refId = "C";
        relativeTimeRange = {
          from = 600;
          to = 0;
        };
        datasourceUid = "__expr__";
        model = {
          refId = "C";
          type = "threshold";
          expression = "B";
          datasource = {
            type = "__expr__";
            uid = "__expr__";
          };
          conditions = [
            {
              type = "query";
              evaluator = {
                type = op;
                params = [threshold];
              };
            }
          ];
        };
      }
    ];
  };

  # ixian suspends itself when idle (machines/ixian/_suspend.nix). Before it
  # sleeps it reports node_suspended=1 and the RTC wake it set (0 if none)
  # through its textfile collector; after waking it reports 0. A sleeping host
  # sends nothing, so the last report is read back with last_over_time. It
  # sleeps at most from one weekend's RTC wake to the next, inside the 7 days.
  suspendingHost = "ixian";
  silent = "(1 - (count(alloy_build_info{instance=\"${suspendingHost}\"}) or vector(0)))";
  plannedSleep = "(max(last_over_time(node_suspended{instance=\"${suspendingHost}\"}[7d])) or vector(0))";
  plannedWake = "max(last_over_time(node_suspend_expected_wake_timestamp_seconds{instance=\"${suspendingHost}\"}[7d]))";
in {
  apiVersion = 1;
  groups = [
    {
      orgId = 1;
      name = "tier1-critical";
      folder = "Homelab Alerts";
      interval = "1m";
      rules = [
        (mkAlert {
          uid = "t1_service_down";
          title = "Service unreachable (probe)";
          expr = "probe_success";
          op = "lt";
          threshold = 1;
          summary = "{{ $labels.instance }} is unreachable — blackbox probe failing.";
        })
        (mkAlert {
          uid = "t1_cert_expiring";
          title = "TLS certificate expiring (<3d)";
          expr = "(probe_ssl_earliest_cert_expiry - time()) / 86400";
          op = "lt";
          threshold = 3;
          pending = "15m";
          summary = "TLS cert for {{ $labels.instance }} expires in under 3 days — ACME renewal may be stuck.";
        })
        (mkAlert {
          uid = "t1_backup_failed";
          title = "Backup failed";
          expr = "homelab_backup_success";
          op = "lt";
          threshold = 1;
          summary = "Backup pipeline failed on {{ $labels.instance }}.";
        })
        (mkAlert {
          uid = "t1_backup_stale";
          title = "Backup stale (>26h)";
          expr = "(time() - homelab_backup_last_success_timestamp_seconds) / 3600";
          op = "gt";
          threshold = 26;
          summary = "No successful backup on {{ $labels.instance }} in over 26 hours.";
        })
        (mkAlert {
          uid = "t1_backup_paths";
          title = "Backup path dropped";
          expr = "homelab_backup_paths_configured - homelab_backup_paths_present";
          op = "gt";
          threshold = 0;
          summary = "A configured backup path is missing on {{ $labels.instance }} (present < configured).";
        })
        (mkAlert {
          uid = "t1_smart_failing";
          title = "Disk SMART health failing";
          expr = "smartctl_device_smart_status";
          op = "lt";
          threshold = 1;
          summary = "SMART self-assessment FAILED on {{ $labels.instance }} device {{ $labels.device }}.";
        })
        (mkAlert {
          uid = "t1_disk_full";
          title = "Filesystem almost full (<5%)";
          expr = "100 * node_filesystem_avail_bytes{fstype!~\"tmpfs|ramfs|overlay|squashfs|efivarfs|nsfs|devtmpfs|autofs|fuse.*\"} / node_filesystem_size_bytes";
          op = "lt";
          threshold = 5;
          pending = "10m";
          summary = "{{ $labels.instance }} {{ $labels.mountpoint }} has less than 5% free.";
        })
        (mkAlert {
          uid = "t1_zfs_unhealthy";
          title = "ZFS pool not healthy";
          expr = "zfs_pool_health";
          op = "gt";
          threshold = 0;
          pending = "1m";
          summary = "ZFS pool {{ $labels.pool }} on {{ $labels.instance }} is not ONLINE.";
        })
        # Graded sensor states only (temperature / voltage / discrete sensors);
        # fan state is intentionally excluded — the BMC flags slow-but-spinning
        # fans as critical, which is chronic noise. A genuinely stopped fan is
        # caught by t1_ipmi_fan_stopped below.
        (mkAlert {
          uid = "t1_ipmi_critical";
          title = "IPMI sensor critical";
          expr = "{__name__=~\"ipmi_(temperature|voltage|sensor)_state\"}";
          op = "gt";
          threshold = 1;
          pending = "2m";
          summary = "IPMI sensor {{ $labels.name }} on {{ $labels.instance }} is in a critical state.";
        })
        (mkAlert {
          uid = "t1_ipmi_fan_stopped";
          title = "IPMI fan stopped";
          expr = "ipmi_fan_speed_rpm";
          op = "lt";
          threshold = 1;
          pending = "2m";
          summary = "IPMI fan {{ $labels.name }} on {{ $labels.instance }} has stopped (0 RPM).";
        })
        # Dead-man's switch: the fleet uses remote-write (no per-target `up`), so
        # this watches the count of hosts reporting telemetry. Threshold is the
        # expected number of Alloy agents reporting to this Prometheus, not
        # counting ixian (it suspends on purpose; the two rules below cover it);
        # bump it when hosts are added/removed. noData=Alerting so a total
        # blackout fires.
        (mkAlert {
          uid = "t1_host_silent";
          title = "Host silent (telemetry stopped)";
          expr = "count(group by (instance) (alloy_build_info{instance!=\"${suspendingHost}\"}))";
          op = "lt";
          threshold = 7;
          noData = "Alerting";
          summary = "Fewer hosts are reporting telemetry than expected — a host or its Alloy agent is down.";
        })
        # ixian sends nothing and its last report wasn't a planned suspend:
        # a crash, power cut, or network loss rather than idle sleep.
        (mkAlert {
          uid = "t1_ixian_silent";
          title = "ixian silent (not a planned suspend)";
          expr = "${silent} * (1 - ${plannedSleep})";
          op = "gt";
          threshold = 0;
          instant = true;
          summary = "ixian stopped sending telemetry without reporting a planned suspend — it may have crashed or lost power or network.";
        })
        # ixian suspended with an RTC wake set (the weekly upgrade or nix-gc)
        # and is still silent 30 minutes after it.
        (mkAlert {
          uid = "t1_ixian_wake_overdue";
          title = "ixian didn't wake as planned";
          expr = "${silent} * ${plannedSleep} * ((time() - ${plannedWake}) > bool 1800) * (${plannedWake} > bool 0)";
          op = "gt";
          threshold = 0;
          instant = true;
          summary = "ixian was due to wake from suspend for a scheduled job over 30 minutes ago and is still silent.";
        })
      ];
    }
  ];
}
