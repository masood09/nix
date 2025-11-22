{
  homelabCfg,
  lib,
  ...
}: let
  zoxideEnabled = homelabCfg.programs.zoxide.enable or false;
  bashEnabled = homelabCfg.programs.bash.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    cd = "z";
  };
in {
  programs = {
    zoxide = {
      inherit (homelabCfg.programs.zoxide) enable;
      enableBashIntegration = bashEnabled;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;
    };

    bash = lib.mkIf zoxideEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf zoxideEnabled {
      inherit shellAliases;
    };

    zsh = lib.mkIf zoxideEnabled {
      inherit shellAliases;
    };
  };
}
