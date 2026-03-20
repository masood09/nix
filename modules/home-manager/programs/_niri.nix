# Niri desktop (home-manager side) — fuzzel launcher,
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
      # Wayland app launcher (Mod+D)
      fuzzel = {
        enable = true;
      };
    };
  };
}
