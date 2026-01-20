{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;

  resticEnabled = homelabCfg.services.restic.enable;
  resticS3Enabled = homelabCfg.services.restic.s3Enable;

  zfsDatasets = homelabCfg.zfs.datasets or {};
  resticDatasetEntries =
    lib.filterAttrs (_: ds: (ds.restic.enable or false)) zfsDatasets;

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
in {
  config = lib.mkIf (resticEnabled && resticS3Enabled && datasetNames != []) {
    systemd.services.restic-zfs-cleanup = {
      description = "Cleanup ZFS snapshot mounts after restic backups";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${cleanupScript}";
        User = "root";
      };
      path = with pkgs; [zfs util-linux coreutils];
    };

    systemd.timers.restic-zfs-cleanup = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "*-*-* 8:00:00";
        Persistent = true;
      };
    };
  };
}
