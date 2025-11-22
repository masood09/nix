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
    bash = lib.mkIf emacsEnabled {
      inherit shellAliases;
    };

    fish = lib.mkIf emacsEnabled {
      inherit shellAliases;
    };

    zsh = lib.mkIf emacsEnabled {
      inherit shellAliases;
    };
  };
}
