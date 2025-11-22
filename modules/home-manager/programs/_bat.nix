{
  homelabCfg,
  lib,
  ...
}: let
  batEnabled = homelabCfg.programs.bat.enable or false;

  shellAliases = {
    cat = "bat";
  };
in {
  programs = {
    bat = {
      inherit (homelabCfg.programs.bat) enable;
    };

    bash = lib.mkIf batEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf batEnabled {
      inherit shellAliases;
    };

    zsh = lib.mkIf batEnabled {
      inherit shellAliases;
    };
  };
}
