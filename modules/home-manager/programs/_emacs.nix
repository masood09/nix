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

  enableEmacs = homelabCfg.programs.emacs.enable or false;
in {
  programs = {
    fd = {
      enable = enableEmacs;
    };

    ripgrep = {
      enable = enableEmacs;
    };
  };

  home = {
    packages = lib.optionals enableEmacs (with pkgs; [
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
}
