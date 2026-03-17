{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  emacsEnabled = homelabCfg.programs.emacs.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    em = "emacsclient -c -n -a ''";
  };
in {
  home = {
    packages = lib.optionals emacsEnabled (
      lib.optional pkgs.stdenv.isLinux pkgs.emacs
      ++ (with pkgs; [
        cmake
        fontconfig
        gomodifytags
        gopls
        gore
        gotests
        jsbeautifier
        multimarkdown
        nil
        nixfmt-rfc-style
        nodejs
        shellcheck
        stylelint
        terraform
      ])
    );
  };

  programs = {
    bash = lib.mkIf emacsEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf (emacsEnabled && fishEnabled) {
      inherit shellAliases;
    };

    zsh = lib.mkIf (emacsEnabled && zshEnabled) {
      inherit shellAliases;
    };
  };
}
