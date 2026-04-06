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
      ++ lib.optionals (role == "desktop" && pkgs.stdenv.isLinux) (with pkgs; [
        # Linux-only desktop GUI apps. Keep user-facing applications here so
        # they follow the desktop role rather than individual machine configs.
        # Bitwarden's matching system-auth policy still lives in the NixOS
        # desktop module because polkit actions are system-wide state; Element
        # Desktop has no comparable machine-wide integration in this repo.
        bitwarden-desktop
        element-desktop
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
