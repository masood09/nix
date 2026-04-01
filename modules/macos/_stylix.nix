# macOS-level Stylix — single source of truth for Base16 theming on Darwin.
# Mirrors modules/nixos/_stylix.nix but without NixOS-specific options
# (cursor is not supported by Stylix's darwinModules).
# Scheme, polarity, wallpaper, fonts, and opacity propagate to Home-Manager
# automatically via Stylix's autoImport + followSystem.
# HM-only target overrides are injected through home-manager.sharedModules.
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

      opacity = {
        terminal = 0.90;
        popups = 0.90;
      };
    };

    # HM-only target overrides — injected via sharedModules so they apply
    # after the Stylix HM module is auto-imported.
    home-manager = {
      sharedModules = [
        {
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
