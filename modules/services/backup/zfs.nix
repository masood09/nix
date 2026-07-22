# Backup sub-module — ZFS snapshot + restic orchestration (stop services,
# snapshot, mount, backup, unmount, restart).
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;

  resticEnabled = homelabCfg.services.restic.enable;

  zfsDatasets = homelabCfg.zfs.datasets;
  resticDatasetEntries = lib.filterAttrs (_: ds: ds.restic.enable) zfsDatasets;

  datasetNames = lib.attrNames resticDatasetEntries;

  backupRoot = toString homelabCfg.services.backup.backupRoot;
  mountPathFor = name: "${backupRoot}/${name}";

  cleanupScript = pkgs.writeShellScript "restic-zfs-cleanup" ''
    set +euo pipefail

    ${lib.concatStringsSep "\n" (map (name: let
        ds = resticDatasetEntries.${name};

        inherit (ds) dataset;

        mnt = mountPathFor name;
        snap = "${dataset}@restic_nightly";
      in ''
        echo "=== Cleaning up ${name} (${dataset}) ==="

        umount "${mnt}" 2>/dev/null || true
        rmdir "${mnt}" 2>/dev/null || true
        zfs destroy "${snap}" 2>/dev/null || true
      '')
      datasetNames)}
  '';

  snapNameFor = name: "${resticDatasetEntries.${name}.dataset}@restic_nightly";

  poolOf = dataset: builtins.head (lib.splitString "/" dataset);

  # `zfs snapshot` is atomic across every name in a single invocation, but only
  # within one pool — it refuses names spanning pools. So group by pool and
  # issue one call each.
  namesByPool =
    lib.groupBy (name: poolOf resticDatasetEntries.${name}.dataset) datasetNames;

  prepareScript = pkgs.writeShellScript "restic-zfs-prepare" ''
    set -euo pipefail
    mkdir -p "${backupRoot}"

    # Phase 1 — clear anything a previous run left behind.
    ${lib.concatMapStringsSep "\n" (name: ''
        umount "${mountPathFor name}" 2>/dev/null || true
        zfs destroy "${snapNameFor name}" 2>/dev/null || true
      '')
      datasetNames}

    # Phase 2 — snapshot, one call per pool, back to back with no other work
    # in between. Previously this was a per-dataset loop with a mount after
    # each snapshot, so the 14 datasets on heartbeat were captured across
    # roughly a second of wall clock and were not consistent with each other.
    # That matters for services split over several datasets: opencloud spans
    # five, and matrix-synapse's database and media store are two more.
    #
    # Cross-pool atomicity is not reachable with ZFS alone, and both of those
    # services do straddle fpool and dpool here. Issuing the calls
    # consecutively narrows that residual window to the gap between two
    # syscalls, which is the best available without quiescing the services.
    ${lib.concatMapStringsSep "\n" (pool: ''
        echo "=== Snapshotting ${toString (builtins.length namesByPool.${pool})} dataset(s) on ${pool} ==="
        zfs snapshot ${lib.concatMapStringsSep " \\\n          " snapNameFor namesByPool.${pool}}
      '')
      (lib.attrNames namesByPool)}

    # Phase 3 — mount the snapshots read-only for restic.
    ${lib.concatMapStringsSep "\n" (name: ''
        echo "=== Staging ${name} (${resticDatasetEntries.${name}.dataset}) ==="
        mkdir -p "${mountPathFor name}"
        mount -t zfs -o ro "${snapNameFor name}" "${mountPathFor name}"
      '')
      datasetNames}
  '';
in {
  config = lib.mkIf (resticEnabled && datasetNames != []) {
    systemd = {
      services = {
        backup-restic-zfs-dataset-cleanup = {
          description = "Cleanup ZFS snapshot mounts after restic backups";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${cleanupScript}";
            User = "root";
          };
          path = [pkgs.zfs pkgs.util-linux pkgs.coreutils];
        };

        backup-restic-zfs-dataset-prepare = {
          description = "Prepare ZFS snapshot mounts for restic backups";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${prepareScript}";
            User = "root";
          };
          path = [pkgs.zfs pkgs.util-linux pkgs.coreutils];
        };
      };

      tmpfiles = {
        rules = [
          "d ${backupRoot} 0750 root root -"
        ];
      };
    };
  };
}
