# NixOS-level Stylix — single source of truth for Base16 theming.
# Scheme, polarity, wallpaper, fonts, cursor, icons, and opacity are defined here
# once and propagate to Home-Manager automatically via Stylix's autoImport
# (imports homeModules.stylix for every HM user) and followSystem (copies
# these values into HM config with mkDefault priority).
#
# Desktop vs server split: Stylix's autoEnable defaults every target to true,
# but servers only benefit from console and grub theming. This module disables
# GTK, Qt, KDE, and GNOME targets on servers (both NixOS-level and HM-level)
# and turns off NixOS XDG sound/icon/mime assets. Without these gates the
# server closure pulls ~1 GB of Qt/GTK/Wayland libraries and theme packages.
#
# HM-only target overrides (starship, waybar, zen-browser) and the Papirus
# icon theme are injected through home-manager.sharedModules since those
# targets don't exist at the NixOS level.
# Darwin counterpart: modules/macos/_stylix.nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.stylix;
  isDesktop = config.homelab.role == "desktop";
in {
  options = {
    homelab = {
      stylix = {
        enable = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = ''
            Stylix Base16 theming (system + home-manager). Enabled by default;
            set to false to opt a machine out.
          '';
        };

        polarity = lib.mkOption {
          default = "dark";
          type = lib.types.enum [
            "dark"
            "light"
          ];
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

      cursor = lib.mkIf isDesktop {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Classic";
        size = 24;
      };

      opacity = {
        terminal = 0.90;
        popups = 0.90;
      };

      # Servers only benefit from console and grub theming. Disable targets
      # that pull GTK, Qt, cursor, and icon packages into the closure —
      # qt5ct/qt6ct/kvantum alone add ~1.4 GB of Qt/Wayland dependencies.
      targets = lib.mkIf (!isDesktop) {
        gtk = {
          enable = false;
        };
        qt = {
          enable = false;
        };
      };
    };

    # Disable NixOS-level XDG desktop assets on servers — sound-theme-freedesktop,
    # shared-mime-info, and hicolor-icon-theme are useless on headless machines.
    # Lives here rather than in a dedicated module because the motivation is the
    # same Stylix-on-servers closure cleanup.
    xdg = lib.mkIf (!isDesktop) {
      sounds = {
        enable = false;
      };
      icons = {
        enable = false;
      };
      mime = {
        enable = false;
      };
    };

    # HM-only target overrides and icon theme — injected via sharedModules
    # so they apply after the Stylix HM module is auto-imported.
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
              # Disable desktop toolkit theming on servers to keep closures lean.
              # These targets inject qt5ct, qt6ct, kvantum, adw-gtk3,
              # stylix-kde-theme, gnome-shell-extension-user-themes,
              # bibata-cursors, and papirus-icon-theme into the HM profile.
              gtk = {
                enable = isDesktop;
              };
              qt = {
                enable = isDesktop;
              };
              kde = {
                enable = isDesktop;
              };
              gnome = {
                enable = isDesktop;
              };
            };
          };

          # Papirus icon theme — provides application icons for desktop shells
          # (Noctalia, launchers, etc.) and GTK apps. Desktop only.
          gtk = lib.mkIf isDesktop {
            iconTheme = {
              package = pkgs.papirus-icon-theme;
              name = "Papirus-Dark";
            };
          };
        }
      ];
    };
  };
}
