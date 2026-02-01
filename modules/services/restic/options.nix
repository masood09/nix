{lib, ...}: {
  options.homelab.services.restic = {
    enable = lib.mkEnableOption "Enable restic backups";

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
}
