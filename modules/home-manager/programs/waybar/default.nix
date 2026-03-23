# Waybar — status bar for niri, active when Noctalia shell is disabled.
# Inspired by sejjy/mechabar: powerline dividers, per-module backgrounds, state colors.
# CSS colors are sourced from Stylix (base16) via Nix interpolation, so the bar
# re-themes automatically whenever the active scheme changes.
{
  config,
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
  noctaliaEnabled = (homelabCfg.desktop.noctalia.enable or false) && pkgs.stdenv.isLinux;
  waybarEnabled = niriEnabled && !noctaliaEnabled;
in {
  config = lib.mkIf waybarEnabled {
    home = {
      packages = with pkgs; [
        brightnessctl # Backlight scroll control
        playerctl # MPRIS media controls
        pavucontrol # Audio mixer on-click
      ];
    };

    programs = {
      waybar = {
        enable = true;
        settings = import ./settings.nix;
        style = import ./style.nix {inherit (config.lib.stylix) colors;};
      };
    };

    # Provide full custom CSS — disable Stylix auto-theming for waybar
    stylix = {
      targets = {
        waybar = {
          enable = false;
        };
      };
    };
  };
}
