# Noctalia Shell — desktop shell environment for niri
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in {
  options = {
    homelab = {
      desktop = {
        noctalia = {
          enable = lib.mkEnableOption "Noctalia shell environment";
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.desktop.noctalia.enable {
    environment = {
      systemPackages = [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];
    };
  };
}
