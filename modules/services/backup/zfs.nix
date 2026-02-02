{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;

  resticEnabled = homelabCfg.services.restic.enable;

  zfsDatasets = homelabCfg.zfs.datasets or {};
  resticDatasetEntries = lib.filterAttrs (_: ds: (ds.restic.enable or false)) zfsDatasets;

  datasetNames = lib.attrNames resticDatasetEntries;

  backupRoot = "/mnt/nightly_backup";
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

  prepareScript = pkgs.writeShellScript "restic-zfs-prepare" ''
    set -euo pipefail
    mkdir -p "${backupRoot}"

    ${lib.concatStringsSep "\n" (map (name: let
        ds = resticDatasetEntries.${name};

        inherit (ds) dataset;

        mnt = mountPathFor name;
        snap = "${dataset}@restic_nightly";
      in ''
        echo "=== Staging ${name} (${dataset}) ==="

        mkdir -p "${mnt}"
        umount "${mnt}" 2>/dev/null || true
        zfs destroy "${snap}" 2>/dev/null || true

        zfs snapshot "${snap}"
        mount -t zfs "${snap}" "${mnt}"

        # defensive
        mount -o remount,ro "${mnt}" 2>/dev/null || true
      '')
      datasetNames)}
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
          path = with pkgs; [zfs util-linux coreutils];
        };

        backup-restic-zfs-dataset-prepare = {
          description = "Prepare ZFS snapshot mounts for restic backups";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${prepareScript}";
            User = "root";
          };
          path = with pkgs; [zfs util-linux coreutils];
        };
      };

      tmpfiles.rules = [
        "d ${backupRoot} 0750 root root -"
      ];
    };
  };
}
