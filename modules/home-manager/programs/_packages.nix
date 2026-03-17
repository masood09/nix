{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (homelabCfg) role;

  globalPkgs = with pkgs; [
    # Packages that are global.
  ];
in {
  home = {
    packages =
      globalPkgs
      ++ lib.optionals (role == "server") (with pkgs; [
        # Packages to be installed only on servers
      ])
      ++ lib.optionals (role == "desktop") (with pkgs; [
        # Packages to be installed only on desktops (laptops/macs)
        age
        alejandra
        findutils
        gnutar
        go
        just
        jq
        oci-cli
        opentofu
        restic
        sops
        statix
        stow
        xz
        awscli2

        # Fonts
        julia-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
        nerd-fonts.symbols-only
        nerd-fonts.hack
        symbola
      ])
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isLinux) [
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      ]
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isDarwin) (with pkgs; [
        coreutils
        coreutils-prefixed
        nixos-rebuild
      ]);
  };
}
