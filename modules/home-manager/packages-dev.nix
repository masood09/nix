{
  pkgs,
  inputs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config = {
      allowUnfree = true;
      dontPatchELF = true;

      packageOverrides = pkgs: {
        inherit (pkgs) stdenv;
      };

      documentation.enable = false;
      man.enable = false;
      info.enable = false;
    };
  };
in {
  imports = [
    ./neovim.nix
  ];

  home = {
    packages = with pkgs; [
      alejandra
      ansible
      cmake
      coreutils-prefixed
      fluxcd
      glibtool
      go
      gomodifytags
      gopls
      gore
      gotests
      jsbeautifier
      just
      jq
      multimarkdown
      nil
      nixfmt-rfc-style
      nixos-rebuild # need for macOS
      oci-cli
      opentofu
      pkgs-unstable.vscode-json-languageserver
      restic
      shellcheck
      statix
      stylelint
      terraform
      terraform-ls
      yaml-language-server
      yq-go
    ];
  };
}
