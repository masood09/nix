# Niri desktop (home-manager side) — settings, fuzzel launcher, brightness/media controls
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
  scripts = import ./scripts.nix {inherit pkgs;};
in {
  config = lib.mkIf niriEnabled {
    home = {
      packages = with pkgs; [
        brightnessctl # Backlight control (XF86MonBrightness* keys)
        playerctl # MPRIS media player control (XF86Audio* keys)
      ];
    };

    programs = {
      # Niri settings (declarative configuration)
      niri = {
        settings = import ./settings.nix {inherit scripts;};
      };

      # Wayland app launcher (Mod+D)
      fuzzel = {
        enable = true;
      };
    };
  };
}
