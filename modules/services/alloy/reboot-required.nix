# Node-level "reboot required" signal for the textfile collector. Compares the
# booted system's kernel/initrd/kernel-modules against the current system's and
# emits node_reboot_required 0|1, so the fleet health board can flag a host that
# has a newer kernel built but not yet booted (NOTICE tier). Mirrors the backup
# service's atomic-write pattern into homelab.services.alloy.textfileDir.
{
  config,
  lib,
  pkgs,
  ...
}: let
  alloyCfg = config.homelab.services.alloy;
  textfileDir = toString alloyCfg.textfileDir;

  writeScript = pkgs.writeShellScript "write-reboot-required" ''
    # No `set -e`: a reporting hiccup must never take down the timer.
    set -uo pipefail

    [ -d "${textfileDir}" ] || exit 0

    _now="$(date +%s)"

    # Preserve the "pending since" stamp across runs so the health board can age
    # a long-outstanding reboot (NOTICE -> WARN at 30d -> CRITICAL at 60d).
    _since=0
    if [ -f "${textfileDir}/reboot-required.prom" ]; then
      _since="$(awk '/^node_reboot_required_since_seconds /{print $2}' \
        "${textfileDir}/reboot-required.prom" 2>/dev/null | tail -1)"
      [ -n "$_since" ] || _since=0
    fi

    # A reboot is needed when the running kernel/initrd/modules differ from the
    # ones the current system generation would boot.
    booted="$(readlink /run/booted-system/{initrd,kernel,kernel-modules} 2>/dev/null)"
    current="$(readlink /run/current-system/{initrd,kernel,kernel-modules} 2>/dev/null)"

    if [ "$booted" = "$current" ]; then
      v=0
      _since=0
    else
      v=1
      # Stamp the first time we notice; keep the earlier stamp thereafter.
      [ "$_since" = "0" ] && _since="$_now"
    fi

    _tmp="$(mktemp "${textfileDir}/.reboot-required.prom.XXXXXX")" || exit 0
    printf '%s\n' \
      '# HELP node_reboot_required Booted system differs from the current system kernel/initrd (1 = reboot required).' \
      '# TYPE node_reboot_required gauge' \
      "node_reboot_required $v" \
      '# HELP node_reboot_required_since_seconds Unix time the current pending reboot was first detected (0 = none).' \
      '# TYPE node_reboot_required_since_seconds gauge' \
      "node_reboot_required_since_seconds $_since" \
      > "$_tmp"
    chmod 0644 "$_tmp"
    # Atomic rename — the collector never sees a half-written file.
    mv -f "$_tmp" "${textfileDir}/reboot-required.prom"
  '';
in {
  config = lib.mkIf alloyCfg.enable {
    systemd = {
      services = {
        reboot-required-metric = {
          description = "Write node_reboot_required to the Alloy textfile collector";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = writeScript;
          };
        };
      };

      timers = {
        reboot-required-metric = {
          description = "Refresh node_reboot_required periodically";
          wantedBy = ["timers.target"];
          timerConfig = {
            OnBootSec = "2min";
            OnUnitActiveSec = "15min";
            Persistent = true;
          };
        };
      };
    };
  };
}
