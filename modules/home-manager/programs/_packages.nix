# User packages — role-based package lists for servers, Linux desktops, and macOS.
# Desktop dev CLIs are shared across Linux and macOS;
# GUI apps, fonts, and platform-specific packages are split by stdenv.
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
        inter

        # Monospace
        fira-code
        fira-code-symbols
        jetbrains-mono
        julia-mono
        terminus_font
        maple-mono.NF

        # Nerd Fonts (patched with icons/glyphs)
        nerd-fonts.symbols-only
        nerd-fonts.fira-code
        nerd-fonts.droid-sans-mono
        nerd-fonts.jetbrains-mono
        nerd-fonts.meslo-lg
        nerd-fonts.hack

        # Icons / emoji
        noto-fonts-color-emoji
        font-awesome
        material-icons
      ]);
  };
}
