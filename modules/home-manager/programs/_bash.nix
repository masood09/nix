{homelabCfg, ...}: {
  programs = {
    bash = {
      inherit (homelabCfg.programs.bash) enable;
    };
  };
}
