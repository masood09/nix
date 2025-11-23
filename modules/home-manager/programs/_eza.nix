{
  homelabCfg,
  lib,
  ...
}: let
  ezaEnabled = homelabCfg.programs.eza.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    ls = "eza --color=always --git --icons=always";
  };
in {
  programs = {
    eza = {
      inherit (homelabCfg.programs.eza) enable;
      enableBashIntegration = true;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;
    };

    bash = lib.mkIf ezaEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf (ezaEnabled && fishEnabled) {
      inherit shellAliases;
    };

    zsh = lib.mkIf (ezaEnabled && zshEnabled) {
      inherit shellAliases;
    };
  };
}
