# NixOS-level Stylix — single source of truth for Base16 theming.
# Scheme, polarity, wallpaper, fonts, cursor, icons, and opacity are defined here
# once and propagate to Home-Manager automatically via Stylix's autoImport
# (imports homeModules.stylix for every HM user) and followSystem (copies
# these values into HM config with mkDefault priority).
# HM-only target overrides (starship, waybar, zen-browser) and the Papirus
# icon theme are injected
# through home-manager.sharedModules since those targets don't exist at the
# NixOS level.
# Darwin counterpart: modules/macos/_stylix.nix.
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
        enable = lib.mkEnableOption "Stylix Base16 theming (system + home-manager)";

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

      base16Scheme =
        if builtins.isPath cfg.scheme
        then cfg.scheme
        else "${pkgs.base16-schemes}/share/themes/${cfg.scheme}.yaml";

      inherit (cfg) polarity;

      image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;

      fonts = {
        sizes = {
          terminal = 12;
          applications = 12;
        };

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

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };

      opacity = {
        terminal = 0.90;
        popups = 0.90;
      };
    };

    # HM-only target overrides and icon theme — injected via sharedModules
    # so they apply after the Stylix HM module is auto-imported.
    home-manager = {
      sharedModules = [
        {
          # Papirus icon theme — provides application icons for desktop shells
          # (Noctalia, launchers, etc.) and GTK apps.
          gtk = {
            iconTheme = {
              package = pkgs.papirus-icon-theme;
              name = "Papirus-Dark";
            };
          };

          stylix = {
            targets = {
              # Starship uses hardcoded Catppuccin colors
              starship = {
                enable = false;
              };
              # Keep color variables and fonts, drop layout/padding/tooltip CSS
              waybar = {
                addCss = false;
              };
              zen-browser = {
                profileNames = ["default"];
              };
            };
          };
        }
      ];
    };
  };
}
