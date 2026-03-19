# User packages — role-based package lists for servers, Linux desktops, and macOS.
# Desktop tools (dev CLIs, fonts) are shared across Linux and macOS;
# GUI apps and platform-specific packages are split by stdenv.
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (homelabCfg) role;

  globalPkgs = with pkgs; [
    # Packages installed on every machine
  ];
in {
  home = {
    packages =
      globalPkgs
      ++ lib.optionals (role == "server") (with pkgs; [
        # Server-only packages
      ])
      ++ lib.optionals (role == "desktop") (with pkgs; [
        # Dev tools and CLIs (shared across Linux and macOS desktops)
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
      # Linux desktop GUI apps
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isLinux) [
        pkgs.bitwarden-desktop
        pkgs.element-desktop
        pkgs.ghostty
        pkgs.opencloud-desktop
        pkgs.zoom-us
      ]
      # macOS-specific (coreutils for GNU compat, nixos-rebuild for remote deploys)
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isDarwin) (with pkgs; [
        coreutils
        coreutils-prefixed
        nixos-rebuild
      ]);
  };
}
