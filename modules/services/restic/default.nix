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

    extraPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra filesystem paths to include in restic backup (in addition to staged ZFS snapshot views).";
    };

    pruneOpts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "--keep-daily 3"
        "--keep-weekly 4"
      ];

      description = "Restic forget/prune retention options passed as pruneOpts.";

      example = [
        "--keep-last 7"
      ];
    };
  };

  config = lib.mkIf resticEnabled {
    services.restic.backups.s3-backup = lib.mkIf (resticS3Enabled && datasetNames != []) {
      initialize = true;

      environmentFile = config.sops.secrets."restic-env".path;
      repositoryFile = config.sops.secrets."restic-repo".path;
      passwordFile = config.sops.secrets."restic-password".path;

      extraOptions = [
        "s3.connections=50"
        "--no-extra-verify"
      ];

      # Restic backs up *already-mounted* snapshot views
      paths = resticPaths ++ homelabCfg.services.restic.extraPaths;
      pruneOpts = homelabCfg.services.restic.pruneOpts;

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
