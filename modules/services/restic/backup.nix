{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.backup;
in {
  options.homelab.services.backup = {
    enable = lib.mkEnableOption "Homelab backup orchestration";

    extraPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra filesystem paths to include in restic backup (in addition to staged ZFS snapshot views).";
    };
  };

  config = lib.mkIf cfg.enable {
    homelab.services.restic.enable = true;
  };
}
