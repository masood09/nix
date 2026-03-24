# Niri desktop (home-manager side) — fuzzel launcher.
# Niri config is managed by DMS via ~/.config/niri/dms/*.kdl
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf niriEnabled {
    programs = {
      # Wayland app launcher
      fuzzel = {
        enable = true;
      };
    };
  };
}
