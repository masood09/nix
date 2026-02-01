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
    ./options.nix
    ./_cleanupZfs.nix
    ./_prepareZfs.nix
  ];

  config = lib.mkIf resticEnabled {
    services.restic.backups.backup = lib.mkIf (resticS3Enabled && datasetNames != []) {
      inherit (homelabCfg.services.restic) pruneOpts;

      initialize = true;

      environmentFile = config.sops.secrets."restic.env".path;
      repositoryFile = config.sops.secrets."restic-repo".path;
      passwordFile = config.sops.secrets."restic-password".path;

      extraOptions = [
        "s3.connections=10"
        "--no-extra-verify"
      ];

      # Restic backs up *already-mounted* snapshot views
      paths = resticPaths ++ homelabCfg.services.restic.extraPaths;

      timerConfig = {
        OnCalendar = "*-*-* 02:00:00";
        Persistent = true;
      };
    };

    systemd.services."restic-backups-backup" = lib.mkIf resticS3Enabled {
      after = ["restic-zfs-prepare.service"];
      wants = ["restic-zfs-prepare.service"];
    };
  };
}
