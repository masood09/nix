# NixOS-level Stylix — system-wide Base16 theming for boot and console.
# Themes Plymouth splash, GRUB boot menu, and the Linux virtual console.
# User-application theming (terminal, GTK, cursor) is handled separately by
# Home-Manager Stylix in modules/home-manager/programs/_stylix.nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.stylix;
in {
  options = {
    homelab = {
      stylix = {
        enable = lib.mkEnableOption "NixOS-level Stylix theming (Plymouth, GRUB, console)";

        polarity = lib.mkOption {
          default = "dark";
          type = lib.types.enum ["dark" "light"];
          description = ''
            Theme polarity (dark or light mode).
          '';
        };

        scheme = lib.mkOption {
          default = "gruvbox-dark";
          type = lib.types.either lib.types.str lib.types.path;
          description = ''
            Base16 color scheme. Either a scheme name from the base16-schemes
            package (e.g. "gruvbox-dark", "catppuccin-mocha") or a path to a
            custom Base16 YAML file (e.g. ../../nix/themes/sonic-dark.yaml).
          '';
        };

        wallpaper = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = ''
            Path to wallpaper image. Stylix will extract colors from this if set.
          '';
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      autoEnable = false;

      # Prevent the NixOS module from injecting its own Stylix config into
      # home-manager users — HM imports homeModules.stylix independently
      # in modules/home-manager/programs/_stylix.nix with its own options.
      # Without this, both modules set the read-only stylix.base16 attr and
      # evaluation fails.
      homeManagerIntegration = {
        autoImport = false;
      };

      base16Scheme =
        if builtins.isPath cfg.scheme
        then cfg.scheme
        else "${pkgs.base16-schemes}/share/themes/${cfg.scheme}.yaml";

      inherit (cfg) polarity;

      image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;

      # Fonts — match HM Stylix config for visual consistency
      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
        sansSerif = {
          package = pkgs.inter;
          name = "Inter";
        };
        serif = {
          package = pkgs.inter;
          name = "Inter";
        };
      };

      # Cursor — match HM Stylix config
      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };

      # Only enable system-level targets — autoEnable is false above so we
      # must opt in explicitly.  HM Stylix handles user-facing targets
      # (terminal, GTK, Qt, waybar, etc.).
      # Plymouth: themed splash on non-ZFS desktops (gated by _boot.nix)
      # GRUB: themed boot menu on ZFS desktops/servers
      # Console: base16 colors on the Linux virtual console (all machines)
      targets = {
        plymouth = {
          enable = true;
        };
        grub = {
          enable = true;
        };
        console = {
          enable = true;
        };
      };
    };
  };
}
