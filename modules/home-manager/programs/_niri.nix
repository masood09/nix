{
  homelabCfg,
  lib,
  inputs,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf niriEnabled {
    programs = {
      fuzzel = {
        enable = true;
      };

      dank-material-shell = {
        enable = true;
        enableSystemMonitoring = true;
        dgop.package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      quickshell = {
        enable = true;
      };
    };
  };
}
