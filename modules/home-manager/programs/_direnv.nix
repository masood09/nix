# Direnv — auto-load .envrc files. nix-direnv caches nix shells for speed.
{homelabCfg, ...}: {
  programs = {
    direnv = {
      inherit (homelabCfg.programs.direnv) enable;

      nix-direnv = {
        enable = homelabCfg.programs.direnv.enable;
      };
    };
  };
}
