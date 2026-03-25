# Emacs — installs emacs-pgtk (native Wayland) on Linux with Doom Emacs
# dependencies (LSPs, formatters, linters). Adds `em` shell alias for
# emacsclient across all enabled shells.
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
      # emacs-pgtk for native Wayland support (standard emacs is X11-only)
      lib.optional pkgs.stdenv.isLinux pkgs.emacs-pgtk
      ++ (with pkgs; [
        # Build deps for :term vterm (native compilation)
        cmake
        gcc
        gnumake
        libtool

        # LSP servers
        gopls # :lang go
        nil # :lang nix
        nodejs # LSP server runtime

        # :lang go tools
        gomodifytags
        gore
        gotests

        # Formatters & linters
        html-tidy # :lang web
        jsbeautifier # :lang web (JS/CSS/HTML formatting)
        nixfmt-rfc-style # :lang nix (nix-format-buffer)
        shellcheck # :lang sh
        stylelint # :lang web

        # Other module deps
        multimarkdown # :lang markdown
        terraform # :tools terraform
        tree-sitter # :tools tree-sitter

        # Fonts required by Doom Emacs
        nerd-fonts.symbols-only # nerd-icons.el
        symbola # Unicode symbol coverage
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
