# Niri compositor — NixOS system-level module.
# Enables the compositor and backlight control (udev rules for the video group).
# User-level tooling (rofi, waybar, mako, etc.) lives in
# modules/home-manager/programs/niri/default.nix.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options = {
    homelab = {
      desktop = {
        niri = {
          enable = lib.mkEnableOption "Niri Wayland compositor";
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.desktop.niri.enable {
    programs = {
      # Backlight control — sets udev rules granting video group write access
      # to /sys/class/backlight/*. Required for brightness keys (light -A/-U).
      light = {
        enable = true;
      };
      niri = {
        enable = true;
        package = pkgs.niri;
      };
    };
  };
}
