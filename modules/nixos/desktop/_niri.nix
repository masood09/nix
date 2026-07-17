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
      # Package provided by niri-flake's NixOS module (inputs.niri.nixosModules.niri
      # included via mkNixOSDesktopConfig); no explicit `package` needed here.
      niri = {
        enable = true;
      };
    };

    # Backlight control — brightnessctl ships udev rules that grant the video
    # group write access to /sys/class/backlight/*, which is what the niri
    # brightness keys (brightnessctl set N%±) need. Replaces programs.light,
    # whose `light` package was removed from nixpkgs in 26.05. Desktop users
    # are already in the video group (see modules/nixos/_users.nix).
    environment = {
      systemPackages = [pkgs.brightnessctl];
    };
    services = {
      udev = {
        packages = [pkgs.brightnessctl];
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
