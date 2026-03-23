# Niri desktop (home-manager side) — fuzzel launcher, brightness/media controls
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf niriEnabled {
    home = {
      packages = with pkgs; [
        brightnessctl # Backlight control (XF86MonBrightness* keys)
        playerctl # MPRIS media player control (XF86Audio* keys)
      ];
    };

    programs = {
      # Wayland app launcher (Mod+D)
      fuzzel = {
        enable = true;
      };
    };
  };
}
