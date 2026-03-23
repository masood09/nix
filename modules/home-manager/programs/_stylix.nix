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

    # Base16 color scheme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${cfg.scheme}.yaml";

    # Theme polarity (dark/light)
    inherit (cfg) polarity;

    # Wallpaper for color extraction (optional)
    image = lib.mkIf (cfg.wallpaper != null) cfg.wallpaper;

    # Fonts (using system defaults, can be customized later)
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrains Mono";
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
