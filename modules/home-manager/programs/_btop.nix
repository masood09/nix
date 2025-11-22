{
  homelabCfg,
  lib,
  ...
}: let
  btopEnabled = homelabCfg.programs.btop.enable or false;

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

    fish = lib.mkIf btopEnabled {
      inherit shellAliases;
    };

    zsh = lib.mkIf btopEnabled {
      inherit shellAliases;
    };
  };
}
