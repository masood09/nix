# Auto-upgrade health + flake staleness signal for the textfile collector.
# nixos-upgrade.service only runs weekly, and node_exporter's systemd
# collector exposes current ActiveState only — not the `Result` of the last
# run, which persists between invocations but isn't scraped. A failed run
# can come and go between scrapes without ever being visible that way.
# Polling `systemctl show -p Result` directly captures the last outcome
# reliably, since systemd retains it until the next run overwrites it.
# Also emits the flake's own commit timestamp (baked in at build time via
# self.lastModified, set from flake.nix) so "how stale is the deployed
# config" doesn't need a live git call from every host.
{
  config,
  lib,
  pkgs,
  ...
}: let
  alloyCfg = config.homelab.services.alloy;
  textfileDir = toString alloyCfg.textfileDir;
  commitTimestamp = alloyCfg.flakeCommitTimestamp;

  writeScript = pkgs.writeShellScript "write-auto-upgrade-status" ''
    # No `set -e`: a reporting hiccup must never take down the timer.
    set -uo pipefail

    [ -d "${textfileDir}" ] || exit 0

    result="$(systemctl show nixos-upgrade.service -p Result --value 2>/dev/null)"
    last_run="$(systemctl show nixos-upgrade.service -p ExecMainExitTimestamp --value 2>/dev/null)"

    if [ "$result" = "success" ]; then
      ok=1
    else
      ok=0
    fi

    last_run_epoch=0
    if [ -n "$last_run" ] && [ "$last_run" != "n/a" ]; then
      last_run_epoch="$(date -d "$last_run" +%s 2>/dev/null || echo 0)"
    fi

    _tmp="$(mktemp "${textfileDir}/.auto-upgrade-status.prom.XXXXXX")" || exit 0
    {
      printf '%s\n' \
        '# HELP node_auto_upgrade_last_result Result of the last nixos-upgrade.service run (1 = success, 0 = failure).' \
        '# TYPE node_auto_upgrade_last_result gauge' \
        "node_auto_upgrade_last_result $ok" \
        '# HELP node_auto_upgrade_last_run_seconds Unix time nixos-upgrade.service last exited (0 = never run).' \
        '# TYPE node_auto_upgrade_last_run_seconds gauge' \
        "node_auto_upgrade_last_run_seconds $last_run_epoch"
      ${lib.optionalString (commitTimestamp != null) ''
      printf '%s\n' \
        '# HELP node_flake_commit_timestamp_seconds Unix time of the deployed flake commit (self.lastModified), baked in at build time.' \
        '# TYPE node_flake_commit_timestamp_seconds gauge' \
        'node_flake_commit_timestamp_seconds ${toString commitTimestamp}'
    ''}
    } > "$_tmp"
    chmod 0644 "$_tmp"
    # Atomic rename — the collector never sees a half-written file.
    mv -f "$_tmp" "${textfileDir}/auto-upgrade-status.prom"
  '';
in {
  config = lib.mkIf alloyCfg.enable {
    systemd = {
      services = {
        auto-upgrade-status-metric = {
          description = "Write auto-upgrade health + flake staleness to the Alloy textfile collector";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = writeScript;
          };
        };
      };

      timers = {
        auto-upgrade-status-metric = {
          description = "Refresh auto-upgrade status periodically";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "5min";
            OnUnitActiveSec = "1h";
            Persistent = true;
          };
        };
      };
    };
  };
}
