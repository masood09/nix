{homelabCfg, ...}: let
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;
in {
  programs = {
    fzf = {
      inherit (homelabCfg.programs.fzf) enable;
      enableBashIntegration = true;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;
    };
  };
}
