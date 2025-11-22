{
  inputs,
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;

    config = {
      allowUnfree = true;
    };
  };

  emacsEnabled = homelabCfg.programs.emacs.enable or false;
  bashEnabled = homelabCfg.programs.bash.enable or false;
  fishEnabled = homelabCfg.programs.fish.enable or false;
  zshEnabled = homelabCfg.programs.zsh.enable or false;

  shellAliases = {
    em = "emacsclient -c -n -a ''";
  };
in {
  home = {
    packages = lib.optionals emacsEnabled (with pkgs; [
      cmake
      coreutils
      gomodifytags
      gopls
      gore
      gotests
      isort
      jsbeautifier
      multimarkdown
      nil
      nixfmt-rfc-style
      nodejs
      pipenv
      shellcheck
      stylelint
      texliveFull
      terraform
      terraform-ls
      pkgs-unstable.vscode-json-languageserver
      yaml-language-server
      yq-go
    ]);
  };

  programs = {
    bash = lib.mkIf (emacsEnabled && bashEnabled) {
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
