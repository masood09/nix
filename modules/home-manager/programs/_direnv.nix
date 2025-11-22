{homelabCfg, ...}: {
  programs.direnv = {
    inherit (homelabCfg.programs.direnv) enable;
    nix-direnv.enable = homelabCfg.programs.direnv.enable;
  };
}
