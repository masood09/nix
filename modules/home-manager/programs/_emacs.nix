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
        # Doom Emacs dependencies: build tools, LSPs, formatters
        cmake
        fontconfig
        gcc # C compiler for tree-sitter/vterm compilation
        gnumake # Required by vterm and other native-compiled Emacs packages
        libtool # Required by vterm to build libvterm
        gomodifytags
        gopls
        gore
        gotests
        jsbeautifier
        multimarkdown
        nil
        nixfmt-rfc-style
        nodejs
        shellcheck
        stylelint
        terraform
        tree-sitter # Syntax highlighting via tree-sitter grammars
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
