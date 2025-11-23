{
  homelabCfg,
  lib,
  ...
}: let
  btopEnabled = homelabCfg.programs.btop.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    top = "btop";
    htop = "btop";
  };
in {
  programs = {
    btop = {
      inherit (homelabCfg.programs.btop) enable;
    };

    bash = lib.mkIf btopEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf (btopEnabled && fishEnabled) {
      inherit shellAliases;
    };

    zsh = lib.mkIf (btopEnabled && zshEnabled) {
      inherit shellAliases;
    };
  };
}
