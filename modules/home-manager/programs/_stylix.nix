# Stylix — Base16 theming system providing fallback themes for all programs.
# Sits at the bottom of the theme hierarchy (Manual > Catppuccin > Stylix).
# Programs with dedicated Catppuccin modules should disable their Stylix targets.
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
    polarity = cfg.polarity;

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

    # Disable Stylix targets for programs that use Catppuccin modules
    # This follows the theme hierarchy: Manual > Catppuccin > Stylix
    targets = {
      bat.enable = false; # Using Catppuccin module
      btop.enable = false; # Using Catppuccin module
      fzf.enable = false; # Using Catppuccin module
      tmux.enable = false; # Using Catppuccin module
      neovim.enable = false; # Using Catppuccin module
      starship.enable = false; # Using Catppuccin module (manual config)
    };
  };
}
