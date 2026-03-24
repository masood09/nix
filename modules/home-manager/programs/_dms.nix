# Dank Material Shell — material-design desktop shell for niri
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  dmsEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf dmsEnabled {
    programs = {
      dank-material-shell = {
        enable = true;
        enableSystemMonitoring = true;

        # dgop is not in nixpkgs stable — use the upstream flake package
        dgop = {
          package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };

        # Launch DMS as a systemd user service
        systemd = {
          enable = true;
          restartIfChanged = true;
        };
      };

      quickshell = {
        enable = true;
      };
    };
  };
}
