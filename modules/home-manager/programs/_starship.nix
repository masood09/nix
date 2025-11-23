{homelabCfg, ...}: let
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;
in {
  programs = {
    starship = {
      inherit (homelabCfg.programs.starship) enable;
      enableBashIntegration = true;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;

      settings = {
        add_newline = false;
      };
    };
  };
}
