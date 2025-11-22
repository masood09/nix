{
  homelabCfg,
  lib,
  ...
}: let
  ezaEnabled = homelabCfg.programs.eza.enable or false;
  bashEnabled = homelabCfg.programs.bash.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    ls = "eza --color=always --git --icons=always";
  };
in {
  programs = {
    eza = {
      inherit (homelabCfg.programs.eza) enable;
      enableBashIntegration = bashEnabled;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;
    };

    bash = lib.mkIf ezaEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf ezaEnabled {
      inherit shellAliases;
    };

    zsh = lib.mkIf ezaEnabled {
      inherit shellAliases;
    };
  };
}
