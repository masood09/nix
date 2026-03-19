# Fastfetch — system info display (neofetch successor).
{homelabCfg, ...}: {
  programs.fastfetch = {
    inherit (homelabCfg.programs.fastfetch) enable;
  };
}
