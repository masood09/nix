# Niri desktop (home-manager side) — Wayland desktop tooling.
# Programs and services with home-manager modules use declarative enablement;
# packages without HM modules are installed directly.
# Backlight control (light) is system-level — see modules/nixos/desktop/_niri.nix.
#
# Shell guard: when homelab.desktop.shell != "none", shell-replaceable programs
# (swaybg, swayidle, swaync, rofi, swaylock, udiskie) are skipped — the
# desktop shell provides equivalent functionality. Compositor-level utilities
# (wl-clipboard, xwayland-satellite) and playerctld remain unconditional.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
  # true when a desktop shell (e.g. quickshell) replaces individual bar/notification/launcher programs
  shellEnabled = (homelabCfg.desktop.shell or "none") != "none";
in {
  imports = [
    ./_waybar.nix
  ];

  config = lib.mkIf niriEnabled {
    # Packages without home-manager modules — compositor utilities are always
    # installed; shell-replaceable packages are conditional on !shellEnabled
    home = {
      packages = with pkgs;
        [
          wl-clipboard # clipboard utilities (no HM module)
          xwayland-satellite # XWayland support for niri (no HM module)
        ]
        ++ lib.optionals (!shellEnabled) [
          swaybg # wallpaper (no HM module)
          swayidle # idle manager, spawned by niri (no HM module)
        ];
    };

    # Systemd user services — shell-replaceable services are gated;
    # playerctld (MPRIS) is always enabled as shells do not replace it
    services = {
      swaync = lib.mkIf (!shellEnabled) {
        enable = true; # notification center with D-Bus activation
      };
      playerctld = {
        enable = true;
      };
      udiskie = lib.mkIf (!shellEnabled) {
        enable = true;
      };
    };

    # Programs managed by home-manager (Stylix auto-themes these) —
    # shell-replaceable; skipped when a desktop shell is active
    programs = {
      rofi = lib.mkIf (!shellEnabled) {
        enable = true;
      };
      swaylock = lib.mkIf (!shellEnabled) {
        enable = true;
      };
    };
  };
}
