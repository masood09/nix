{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;

  resticEnabled = homelabCfg.services.restic.enable;

  zfsDatasets = homelabCfg.zfs.datasets or {};
  resticDatasetEntries =
    lib.filterAttrs (_: ds: (ds.restic.enable or false)) zfsDatasets;

  datasetNames = lib.attrNames resticDatasetEntries;
  extraPaths = homelabCfg.services.backup.extraPaths or [];

  backupRoot = "/mnt/nightly_backup";
  mountPathFor = name: "${backupRoot}/${name}";
  resticPaths = map mountPathFor datasetNames;

  hasResticPaths = (datasetNames != []) || (extraPaths != []);
in {
  config = lib.mkIf resticEnabled {
    services.restic.backups.backup = lib.mkIf hasResticPaths {
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
      paths = resticPaths ++ extraPaths;

      timerConfig = null;
    };
  };
}
