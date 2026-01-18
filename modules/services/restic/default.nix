{
  config,
  lib,
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
  resticPaths = map mountPathFor datasetNames;
in {
  imports = [
    ./_cleanupZfs.nix
    ./_prepareZfs.nix
  ];

  options.homelab.services.restic = {
    enable = lib.mkEnableOption "Enable restic backups";
    s3Enable = lib.mkEnableOption "Enable S3 restic backups";
  };

  config = lib.mkIf resticEnabled {
    services.restic.backups.s3-backup = lib.mkIf (resticS3Enabled && datasetNames != []) {
      initialize = true;

      environmentFile = config.sops.secrets."restic-env".path;
      repositoryFile = config.sops.secrets."restic-repo".path;
      passwordFile = config.sops.secrets."restic-password".path;

      # Restic backs up *already-mounted* snapshot views
      paths = resticPaths;

      pruneOpts = [
        "--keep-daily 1"
        "--keep-weekly 7"
        "--keep-monthly 30"
        "--keep-yearly 12"
      ];

      timerConfig = {
        OnCalendar = "*-*-* 03:00:00";
        Persistent = true;
      };
    };

    systemd.services."restic-backups-s3-backup" = lib.mkIf resticS3Enabled {
      after = ["restic-zfs-prepare.service"];
      wants = ["restic-zfs-prepare.service"];
    };
  };
}
