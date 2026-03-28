# Niri desktop (home-manager side) — Wayland desktop tooling.
# Programs and services with home-manager modules use declarative enablement;
# packages without HM modules are installed directly.
# Backlight control (light) is system-level — see modules/nixos/desktop/_niri.nix.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf niriEnabled {
    # Packages without home-manager modules
    home = {
      packages = with pkgs; [
        swaybg # wallpaper (no HM module)
        swayidle # idle manager, spawned by niri (no HM module)
        wl-clipboard # clipboard utilities (no HM module)
        xwayland-satellite # XWayland support for niri (no HM module)
      ];
    };

    # Systemd user services managed by home-manager
    services = {
      swaync = {
        enable = true; # notification center with D-Bus activation
      };
      playerctld = {
        enable = true;
      };
      udiskie = {
        enable = true;
      };
    };

    # Programs managed by home-manager (Stylix auto-themes these)
    programs = {
      rofi = {
        enable = true;
      };
      swaylock = {
        enable = true;
      };
      waybar = {
        enable = true;
      };
    };
  };
}
