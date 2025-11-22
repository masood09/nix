{
  homelabCfg,
  lib,
  ...
}: let
  ripgrepEnabled = homelabCfg.programs.ripgrep.enable or false;

  shellAliases = {
    grep = "rg";
  };
in {
  programs = {
    ripgrep = {
      inherit (homelabCfg.programs.ripgrep) enable;
    };

    bash = lib.mkIf ripgrepEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf ripgrepEnabled {
      inherit shellAliases;
    };

    zsh = lib.mkIf ripgrepEnabled {
      inherit shellAliases;
    };
  };
}
