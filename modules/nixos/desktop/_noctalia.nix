# Noctalia desktop shell — bar, notifications, launcher, lock screen, wallpaper.
# Installed as a system package (not via its home-manager module).
# When active, the HM niri module skips shell-replaceable programs
# (waybar, swaync, rofi, swaylock, swaybg, udiskie) via the shellEnabled guard.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  config = lib.mkIf (homelabCfg.desktop.shell == "noctalia") {
    environment = {
      systemPackages = [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
