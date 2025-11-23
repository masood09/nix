{
  homelabCfg,
  lib,
  ...
}: let
  ripgrepEnabled = homelabCfg.programs.ripgrep.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

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

    fish = lib.mkIf (ripgrepEnabled && fishEnabled) {
      inherit shellAliases;
    };

    zsh = lib.mkIf (ripgrepEnabled && zshEnabled) {
      inherit shellAliases;
    };
  };
}
