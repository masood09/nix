# Noctalia Shell — desktop shell widgets and panels for niri
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  noctalia_enabled = (homelabCfg.desktop.noctalia.enable or false) && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf noctalia_enabled {
    programs = {
      noctalia-shell = {
        enable = true;
        settings = {
          # Noctalia settings - configure bar, widgets, etc.
          # See: https://docs.noctalia.dev for configuration options
        };
      };
    };
  };
}
