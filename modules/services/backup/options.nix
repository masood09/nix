{lib, ...}: {
  options.homelab.services = {
    backup = {
      enable = lib.mkEnableOption "Homelab backup orchestration";

      extraPaths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Extra filesystem paths to include in restic backup (in addition to staged ZFS snapshot views).";
      };

      serviceUnits = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        example = ["podman-opencloud.service" "postgresql.service"];
        description = "systemd unit names to stop while snapshots/db dumps are taken.";
      };
    };
      
    restic = {
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
  };
}
