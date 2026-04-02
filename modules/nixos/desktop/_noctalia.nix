# Noctalia desktop shell — bar, notifications, launcher, lock screen, wallpaper.
# Installs the system package; HM module is imported in home.nix and enabled
# in modules/home-manager/programs/niri/_noctalia.nix.
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
