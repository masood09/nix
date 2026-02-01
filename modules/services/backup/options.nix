{lib, ...}: {
  options.homelab.services.restic = {
    enable = lib.mkEnableOption "Enable restic backups";

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
