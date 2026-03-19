# Niri desktop (home-manager side) — DankMaterialShell, fuzzel launcher,
# and dark mode dconf setting. Only active on Linux desktops with niri enabled.
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
    # GTK/GNOME apps respect this for dark theme
    dconf = {
      settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
        };
      };
    };

    programs = {
      # Wayland app launcher (Mod+D)
      fuzzel = {
        enable = true;
      };

      # DankMaterialShell — panel/bar for Niri compositor
      dank-material-shell = {
        enable = true;
        enableSystemMonitoring = true;
        dgop = {
          package = inputs.dgop.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
        systemd = {
          enable = true;
          restartIfChanged = true;
        };
      };

      # Quickshell — rendering backend for DMS
      quickshell = {
        enable = true;
      };
    };
  };
}
