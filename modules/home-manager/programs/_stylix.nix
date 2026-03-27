# Stylix — Base16 theming system providing consistent theming for all programs.
# Uses base16 color schemes to automatically theme supported applications.
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.stylix;
in {
  imports = [
    inputs.stylix.homeModules.stylix
  ];

  stylix = lib.mkIf cfg.enable {
    enable = true;

    # Base16 color scheme — path to a custom YAML file, or a named scheme
    # from the base16-schemes package (e.g. "catppuccin-mocha").
    base16Scheme =
      if builtins.isPath cfg.scheme
      then cfg.scheme
      else "${pkgs.base16-schemes}/share/themes/${cfg.scheme}.yaml";

    # Theme polarity (dark/light)
    inherit (cfg) polarity;

    # Wallpaper for color extraction (optional)
    image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;

    # Fonts — families and sizes applied uniformly across terminal and GUI apps
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
        package = pkgs.montserrat;
        name = "Montserrat";
      };
      serif = {
        package = pkgs.montserrat;
        name = "Montserrat";
      };
    };

    # Cursor theme
    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 24;
    };

    # Opacity settings
    opacity = {
      terminal = 0.95;
      popups = 0.95;
    };

    # Disable Starship target - it uses hardcoded Catppuccin colors
    targets = {
      starship = {
        enable = false;
      };
    };
  };
}
