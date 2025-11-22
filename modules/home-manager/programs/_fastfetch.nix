{homelabCfg, ...}: {
  programs.fastfetch = {
    inherit (homelabCfg.programs.fastfetch) enable;
  };
}
