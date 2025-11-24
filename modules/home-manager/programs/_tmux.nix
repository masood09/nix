{homelabCfg, ...}: {
  programs = {
    tmux = {
      inherit (homelabCfg.programs.tmux) enable;
    };
  };
}
