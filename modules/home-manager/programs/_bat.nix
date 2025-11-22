{
  homelabCfg,
  lib,
  ...
}: let
  batEnabled = homelabCfg.programs.bat.enable or false;
  bashEnabled = homelabCfg.programs.bash.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    cat = "bat";
  };
in {
  programs = {
    bat = {
      inherit (homelabCfg.programs.bat) enable;
    };

    bash = lib.mkIf (batEnabled && bashEnabled) {
      inherit shellAliases;
    };

    fish = lib.mkIf (batEnabled && fishEnabled) {
      inherit shellAliases;
    };

    zsh = lib.mkIf (batEnabled && zshEnabled) {
      inherit shellAliases;
    };
  };
}
