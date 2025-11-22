{homelabCfg, ...}: let
  bashEnabled = homelabCfg.programs.bash.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;
in {
  programs = {
    fzf = {
      inherit (homelabCfg.programs.fzf) enable;
      enableBashIntegration = bashEnabled;
      enableFishIntegration = fishEnabled;
      enableZshIntegration = zshEnabled;
    };
  };
}
