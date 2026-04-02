# Noctalia desktop shell (home-manager side) — enables the HM module.
# The HM module is imported in home.nix; this file only activates it
# when the desktop shell is set to "noctalia".
# Configuration will be added to programs.noctalia-shell.settings later.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  shellIsNoctalia = ((homelabCfg.desktop.shell or "none") == "noctalia") && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf shellIsNoctalia {
    programs = {
      noctalia-shell = {
        enable = true;
      };
    };
  };
}
