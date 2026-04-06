# Noctalia desktop shell — bar, notifications, lock screen, wallpaper.
# Installs the package; the HM module is imported in home.nix and configured in
# modules/home-manager/programs/niri/_noctalia.nix, while Niri owns startup via
# programs.niri.settings.spawn-at-startup in modules/home-manager/programs/niri/default.nix.
# Keep Noctalia's experimental systemd user service disabled here to avoid
# double-starting the shell from both systemd and the compositor session.
# When active, the HM niri module skips shell-replaceable programs
# (waybar, swaync, swaylock, swaybg, swayidle, udiskie) via the shellEnabled guard.
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
