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

  config = lib.mkIf cfg.enable {
    homelab.services.restic.enable = true;
  };
}
