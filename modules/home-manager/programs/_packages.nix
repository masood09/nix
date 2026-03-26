# User packages — role-based package lists for servers, desktops, and macOS.
# Tool-specific packages (emacs, oci-cli, etc.) live in their own _<name>.nix
# modules; this file covers shared dev CLIs and platform-specific packages.
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
        go
        just
        jq
        sops
        statix
        stow
      ])
      # Linux desktop — Wayland utilities (gated on niri.enable)
      ++ lib.optionals ((homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux) (with pkgs; [
        wl-clipboard
      ])
      # macOS-specific (coreutils for GNU compat, nixos-rebuild for remote deploys)
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isDarwin) (with pkgs; [
        coreutils
        coreutils-prefixed
        nixos-rebuild

        # Fonts (on NixOS these are installed system-wide via fonts.packages)
        # Sans-serif / serif
        dejavu_fonts
        noto-fonts
        noto-fonts-cjk-sans
        # Emoji
        noto-fonts-color-emoji
      ]);
  };
}
