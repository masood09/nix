# Niri desktop (home-manager side) — settings, fuzzel launcher, brightness/media controls.
# Noctalia shell integration is conditional: spawn and layer-rules only apply when enabled.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
  # Passed into settings.nix to gate Noctalia spawn and layer-rule entries.
  noctaliaEnabled = (homelabCfg.desktop.noctalia.enable or false) && pkgs.stdenv.isLinux;
  # Passed into settings.nix to conditionally spawn swaybg at startup.
  wallpaper = homelabCfg.programs.stylix.wallpaper or null;
  scripts = import ./scripts.nix {inherit pkgs;};
in {
  config = lib.mkIf niriEnabled {
    home = {
      packages = with pkgs; [
        brightnessctl # Backlight control (XF86MonBrightness* keys)
        playerctl # MPRIS media player control (XF86Audio* keys)
        swaybg # Wallpaper setter (spawned at niri startup when wallpaper is set)
      ];
    };

    programs = {
      # Niri settings (declarative configuration)
      niri = {
        settings = import ./settings.nix {inherit lib scripts noctaliaEnabled wallpaper;};
      };

      # Wayland app launcher (Mod+D)
      fuzzel = {
        enable = true;
      };
    };
  };
}
