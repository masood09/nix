# Niri compositor — NixOS module (enables niri system-wide)
# Settings are configured via home-manager (see home-manager/programs/niri)
{
  config,
  inputs,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    inputs.niri.nixosModules.niri
  ];

  options = {
    homelab = {
      desktop = {
        niri = {
          enable = lib.mkEnableOption "Niri Wayland compositor";
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.desktop.niri.enable {
    programs = {
      niri = {
        enable = true;
      };
    };
  };
}
