# Niri compositor — NixOS system-level module.
# Enables the compositor, backlight control (udev rules for the video group),
# and the GTK portal backend for FileChooser (Save As dialogs).
# User-level tooling and compositor config live in
# modules/home-manager/programs/niri/default.nix via niri-flake's HM module.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
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
      # Backlight control — sets udev rules granting video group write access
      # to /sys/class/backlight/*. Required for brightness keys (light -A/-U).
      light = {
        enable = true;
      };
      # Package provided by niri-flake's NixOS module (inputs.niri.nixosModules.niri
      # included via mkNixOSDesktopConfig); no explicit `package` needed here.
      niri = {
        enable = true;
      };
    };

    # niri-flake sets `default=gnome;gtk;` in its portal config and conditionally
    # adds xdg-desktop-portal-gnome (for screencasting). The GNOME backend
    # implements FileChooser but requires a full GNOME session to render the
    # dialog — on a bare niri compositor it accepts the D-Bus request then
    # silently fails. Adding xdg-desktop-portal-gtk and explicitly routing
    # FileChooser to it ensures "Save As" dialogs (e.g. browser downloads
    # with useDownloadDir=false) always appear.
    xdg = {
      portal = {
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
        config = {
          niri = {
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };
        };
      };
    };
  };
}
