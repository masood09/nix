{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.backup;
in {
  imports = [
    ./options.nix
    ./restic.nix
    ./zfs.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab.services.restic.enable = true;
  };
}
