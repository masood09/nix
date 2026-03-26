# Niri desktop (home-manager side) — Wayland utilities and desktop tooling.
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
        brightnessctl # backlight control
        mako # notification daemon
        playerctl # media player control
        rofi # app launcher
        swaybg # wallpaper
        swayidle # idle management
        swaylock # screen locker
        udiskie # auto-mount removable media
        waybar # status bar
        wl-clipboard # clipboard utilities
        xwayland-satellite # XWayland support for niri
      ];
    };
  };
}
