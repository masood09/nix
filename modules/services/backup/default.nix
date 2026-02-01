{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.backup;
in {
  imports = [
    ./restic.nix
    ./options.nix
    ./_cleanupZfs.nix
    ./_prepareZfs.nix
  ];

  options.homelab.services.backup = {
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

  config = lib.mkIf cfg.enable {
    homelab.services.restic.enable = true;
  };
}
