{
  homelabCfg,
  lib,
  ...
}: let
  zoxideEnabled = homelabCfg.programs.zoxide.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    cd = "z";
  };
in {
  programs = {
    zoxide = {
      inherit (homelabCfg.programs.zoxide) enable;
      enableBashIntegration = true;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;
    };

    bash = lib.mkIf zoxideEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf (zoxideEnabled && fishEnabled) {
      inherit shellAliases;
    };

    zsh = lib.mkIf (zoxideEnabled && zshEnabled) {
      inherit shellAliases;
    };
  };
}
