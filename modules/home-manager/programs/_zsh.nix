{homelabCfg, ...}: {
  programs = {
    zsh = {
      inherit (homelabCfg.programs.zsh) enable;
    };
  };
}
