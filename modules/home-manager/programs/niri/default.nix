# Niri desktop (home-manager side) — compositor config plus Wayland helpers.
# Niri itself is configured declaratively through niri-flake's HM module so
# Stylix can theme it; surrounding desktop helpers stay split by desktop.shell.
# Backlight control (light) is system-level — see modules/nixos/desktop/_niri.nix.
#
# Shell guard: when homelab.desktop.shell != "none", shell-replaceable programs
# (swaybg, swayidle, swaync, swaylock, udiskie) are skipped — the desktop
# shell provides equivalent functionality. Rofi remains enabled regardless so
# the compositor-level launcher key stays consistent across shell choices.
# Compositor-level utilities (wl-clipboard, xwayland-satellite) and playerctld
# remain unconditional.
{
  config,
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
  # true when a desktop shell (e.g. Noctalia) replaces shell-owned desktop UI
  # such as the bar, notifications, lock screen, wallpaper, and idle handling
  shellEnabled = (homelabCfg.desktop.shell or "none") != "none";
  stylixEnabled = config.stylix.enable or false;
  wallpaper =
    if stylixEnabled
    then (config.stylix.image or null)
    else null;
  niriBin = "${config.programs.niri.package}/bin/niri";
in {
  imports = [
    ./_noctalia.nix
    ./_waybar.nix
  ];

  config = lib.mkIf niriEnabled {
    home = {
      # Packages without home-manager modules — compositor utilities are always
      # installed; shell-replaceable packages are conditional on !shellEnabled.
      packages = with pkgs;
        [
          wl-clipboard # clipboard utilities (no HM module)
          xwayland-satellite # XWayland support for niri (started as a user service)
        ]
        ++ lib.optionals (!shellEnabled) [
          swaybg # wallpaper helper (started as a user service)
          swayidle # idle manager (started as a user service)
        ];
    };

    programs = {
      niri.settings = {
        # Session-level environment for apps spawned by niri.
        # Suppress the "config reload failed" popup — errors are visible in
        # the journal and the toast is disruptive during iterative rebuilds.
        config-notification = {
          disable-failed = true;
        };

        environment = {
          XDG_CURRENT_DESKTOP = "niri";
          XDG_SESSION_TYPE = "wayland";
          QT_QPA_PLATFORM = "wayland";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
          QT_QPA_PLATFORMTHEME = "gtk3";
          ELECTRON_OZONE_PLATFORM_HINT = "auto";
          NIXOS_OZONE_WL = "1";
        };

        gestures.hot-corners.enable = false;

        input = {
          keyboard = {
            xkb.options = "caps:escape";
            numlock = true;
          };

          touchpad = {
            tap = true;
            natural-scroll = true;
          };

          focus-follows-mouse = {
            enable = true;
            max-scroll-amount = "0%";
          };

          workspace-auto-back-and-forth = true;
        };

        # Layout and decoration defaults. Stylix handles the actual palette
        # where possible so the visual accents follow the active theme.
        layout = {
          gaps = 12;
          background-color = "transparent";
          center-focused-column = "never";

          focus-ring =
            {
              enable = true;
              width = 3;
            }
            // lib.optionalAttrs stylixEnabled {
              active.color = config.lib.stylix.colors.withHashtag.base13;
              inactive.color = config.lib.stylix.colors.withHashtag.base02;
              urgent.color = config.lib.stylix.colors.withHashtag.base08;
            };

          tab-indicator =
            {
              enable = true;
            }
            // lib.optionalAttrs stylixEnabled {
              active.color = config.lib.stylix.colors.withHashtag.base13;
              inactive.color = config.lib.stylix.colors.withHashtag.base04;
              urgent.color = config.lib.stylix.colors.withHashtag.base08;
            };

          insert-hint =
            {
              enable = true;
            }
            // lib.optionalAttrs stylixEnabled {
              display.color = "${config.lib.stylix.colors.withHashtag.base13}80";
            };

          preset-column-widths = [
            {proportion = 0.33333;}
            {proportion = 0.5;}
            {proportion = 0.66667;}
          ];

          default-column-width = {
            proportion = 0.5;
          };

          border.enable = false;
          shadow.enable = false;

          struts = {};
        };

        overview.workspace-shadow.enable = false;

        hotkey-overlay.skip-at-startup = true;
        prefer-no-csd = true;
        screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

        # Animation tuning translated from the old handwritten KDL config to
        # niri-flake's current kind-based schema.
        animations = {
          workspace-switch.kind = {
            spring = {
              damping-ratio = 0.80;
              stiffness = 523;
              epsilon = 0.0001;
            };
          };

          window-open.kind = {
            easing = {
              duration-ms = 150;
              curve = "ease-out-expo";
            };
          };

          window-close.kind = {
            easing = {
              duration-ms = 150;
              curve = "ease-out-quad";
            };
          };

          horizontal-view-movement.kind = {
            spring = {
              damping-ratio = 0.85;
              stiffness = 423;
              epsilon = 0.0001;
            };
          };

          window-movement.kind = {
            spring = {
              damping-ratio = 0.75;
              stiffness = 323;
              epsilon = 0.0001;
            };
          };

          window-resize.kind = {
            spring = {
              damping-ratio = 0.85;
              stiffness = 423;
              epsilon = 0.0001;
            };
          };

          config-notification-open-close.kind = {
            spring = {
              damping-ratio = 0.65;
              stiffness = 923;
              epsilon = 0.001;
            };
          };

          screenshot-ui-open.kind = {
            easing = {
              duration-ms = 200;
              curve = "ease-out-quad";
            };
          };

          overview-open-close.kind = {
            spring = {
              damping-ratio = 0.85;
              stiffness = 800;
              epsilon = 0.0001;
            };
          };
        };

        # Window rules restored from the previous manual config. Keep these in
        # shared config because they apply consistently across both laptops.
        window-rules = [
          {
            # Empty default-column-width lets wezterm use its own requested size
            # rather than the global 50% proportion default.
            matches = [{app-id = "^org\\.wezfurlong\\.wezterm$";}];
            default-column-width = {};
          }
          {
            # Global rule (no `matches`): rounded corners on all tiled windows.
            geometry-corner-radius = {
              bottom-left = 12.0;
              bottom-right = 12.0;
              top-left = 12.0;
              top-right = 12.0;
            };
            clip-to-geometry = true;
            tiled-state = true;
            draw-border-with-background = false;
          }
          {
            matches = [
              {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              }
              {
                app-id = "^zoom$";
              }
            ];
            open-floating = true;
          }
          {
            matches = [
              {
                app-id = "^org\\.gnome\\.Nautilus$";
              }
              {
                app-id = "^xdg-desktop-portal$";
              }
            ];
            open-floating = true;
          }
          {
            matches = [
              {
                app-id = "^org\\.keepassxc\\.KeePassXC$";
              }
              {
                app-id = "^org\\.gnome\\.World\\.Secrets$";
              }
            ];
            block-out-from = "screen-capture";
          }
        ];

        # Work around clients that send XDG activation tokens with an invalid
        # serial — without this, focus-stealing prevention rejects them silently.
        debug.honor-xdg-activation-with-invalid-serial = [];

        # Shared external monitor profile keyed by a stable logical name rather
        # than a transient connector like DP-2. `name` does the real matching.
        outputs = {
          lg-ultrafine = {
            name = "LG Electronics LG ULTRAFINE 110NTHM20241";
            mode = {
              width = 3840;
              height = 2160;
              refresh = 59.997;
            };
            scale = 1.25;
            transform.rotation = 0;
            position = {
              x = 0;
              y = 0;
            };
          };
        };

        # Compositor-native binds. Keep the launcher on Mod+D regardless of the
        # selected desktop shell; shell-owned lock integration stays conditional.
        binds =
          lib.optionalAttrs (!shellEnabled) {
            "Super+Alt+L" = {
              action.spawn = ["swaylock"];
            };
          }
          // {
            "Mod+D" = {
              action.spawn = ["rofi" "-show" "drun"];
            };
            "Mod+Shift+Slash".action.show-hotkey-overlay = {};

            "Mod+Return" = {
              action.spawn = ["kitty"];
            };
            "Super+B" = {
              action.spawn = ["zen-beta"];
            };
            # Orca screen reader — toggle on/off with a single key.
            "Super+Alt+S" = {
              allow-when-locked = true;
              action.spawn-sh = "pkill orca || exec orca";
            };

            # — Media / hardware keys (allow-when-locked for lock-screen use) —
            "XF86AudioRaiseVolume" = {
              allow-when-locked = true;
              action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
            };
            "XF86AudioLowerVolume" = {
              allow-when-locked = true;
              action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
            };
            "XF86AudioMute" = {
              allow-when-locked = true;
              action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            };
            "XF86AudioMicMute" = {
              allow-when-locked = true;
              action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            };

            "XF86AudioPlay" = {
              allow-when-locked = true;
              action.spawn-sh = "playerctl play-pause";
            };
            "XF86AudioStop" = {
              allow-when-locked = true;
              action.spawn-sh = "playerctl stop";
            };
            "XF86AudioPrev" = {
              allow-when-locked = true;
              action.spawn-sh = "playerctl previous";
            };
            "XF86AudioNext" = {
              allow-when-locked = true;
              action.spawn-sh = "playerctl next";
            };

            "XF86MonBrightnessUp" = {
              allow-when-locked = true;
              action.spawn = ["light" "-A" "10"];
            };
            "XF86MonBrightnessDown" = {
              allow-when-locked = true;
              action.spawn = ["light" "-U" "10"];
            };

            "Mod+O" = {
              repeat = false;
              action.toggle-overview = {};
            };
            "Mod+Q" = {
              repeat = false;
              action.close-window = {};
            };

            # — Navigation (arrow keys + vim hjkl) —
            # Primary navigation stays local first, but falls through to the
            # adjacent monitor/workspace at the edge so directional movement
            # does not dead-end on the current container.
            "Mod+Left".action.focus-column-or-monitor-left = {};
            "Mod+Down".action.focus-window-or-workspace-down = {};
            "Mod+Up".action.focus-window-or-workspace-up = {};
            "Mod+Right".action.focus-column-or-monitor-right = {};
            "Mod+H".action.focus-column-or-monitor-left = {};
            "Mod+J".action.focus-window-or-workspace-down = {};
            "Mod+K".action.focus-window-or-workspace-up = {};
            "Mod+L".action.focus-column-or-monitor-right = {};

            # Shift keeps the same fallback semantics while moving the focused
            # column/window instead of only changing focus.
            "Mod+Shift+Left".action.move-column-left-or-to-monitor-left = {};
            "Mod+Shift+Down".action.move-window-down-or-to-workspace-down = {};
            "Mod+Shift+Up".action.move-window-up-or-to-workspace-up = {};
            "Mod+Shift+Right".action.move-column-right-or-to-monitor-right = {};
            "Mod+Shift+H".action.move-column-left-or-to-monitor-left = {};
            "Mod+Shift+J".action.move-window-down-or-to-workspace-down = {};
            "Mod+Shift+K".action.move-window-up-or-to-workspace-up = {};
            "Mod+Shift+L".action.move-column-right-or-to-monitor-right = {};

            "Mod+Home".action.focus-column-first = {};
            "Mod+End".action.focus-column-last = {};
            "Mod+Ctrl+Home".action.move-column-to-first = {};
            "Mod+Ctrl+End".action.move-column-to-last = {};

            # Ctrl variants remain explicit monitor-to-monitor navigation and
            # bypass the local-first fallback behavior above.
            "Mod+Ctrl+Left".action.focus-monitor-left = {};
            "Mod+Ctrl+Down".action.focus-monitor-down = {};
            "Mod+Ctrl+Up".action.focus-monitor-up = {};
            "Mod+Ctrl+Right".action.focus-monitor-right = {};
            "Mod+Ctrl+H".action.focus-monitor-left = {};
            "Mod+Ctrl+J".action.focus-monitor-down = {};
            "Mod+Ctrl+K".action.focus-monitor-up = {};
            "Mod+Ctrl+L".action.focus-monitor-right = {};

            # Shift+Ctrl moves the entire column to a specific monitor
            # (no local-first fallback — always crosses monitor boundary).
            "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = {};
            "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = {};
            "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = {};
            "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = {};
            "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = {};
            "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = {};
            "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = {};
            "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = {};

            "Mod+Page_Down".action.focus-workspace-down = {};
            "Mod+Page_Up".action.focus-workspace-up = {};
            "Mod+U".action.focus-workspace-down = {};
            "Mod+I".action.focus-workspace-up = {};
            "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = {};
            "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = {};
            "Mod+Ctrl+U".action.move-column-to-workspace-down = {};
            "Mod+Ctrl+I".action.move-column-to-workspace-up = {};

            "Mod+Shift+Page_Down".action.move-workspace-down = {};
            "Mod+Shift+Page_Up".action.move-workspace-up = {};
            "Mod+Shift+U".action.move-workspace-down = {};
            "Mod+Shift+I".action.move-workspace-up = {};

            "Mod+WheelScrollDown" = {
              cooldown-ms = 150;
              action.focus-workspace-down = {};
            };
            "Mod+WheelScrollUp" = {
              cooldown-ms = 150;
              action.focus-workspace-up = {};
            };
            "Mod+Ctrl+WheelScrollDown" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-down = {};
            };
            "Mod+Ctrl+WheelScrollUp" = {
              cooldown-ms = 150;
              action.move-column-to-workspace-up = {};
            };
            "Mod+WheelScrollRight".action.focus-column-right = {};
            "Mod+WheelScrollLeft".action.focus-column-left = {};
            "Mod+Ctrl+WheelScrollRight".action.move-column-right = {};
            "Mod+Ctrl+WheelScrollLeft".action.move-column-left = {};
            "Mod+Shift+WheelScrollDown".action.focus-column-right = {};
            "Mod+Shift+WheelScrollUp".action.focus-column-left = {};
            "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = {};
            "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = {};

            "Mod+1".action.focus-workspace = 1;
            "Mod+2".action.focus-workspace = 2;
            "Mod+3".action.focus-workspace = 3;
            "Mod+4".action.focus-workspace = 4;
            "Mod+5".action.focus-workspace = 5;
            "Mod+6".action.focus-workspace = 6;
            "Mod+7".action.focus-workspace = 7;
            "Mod+8".action.focus-workspace = 8;
            "Mod+9".action.focus-workspace = 9;

            "Mod+Shift+1".action.move-column-to-workspace = 1;
            "Mod+Shift+2".action.move-column-to-workspace = 2;
            "Mod+Shift+3".action.move-column-to-workspace = 3;
            "Mod+Shift+4".action.move-column-to-workspace = 4;
            "Mod+Shift+5".action.move-column-to-workspace = 5;
            "Mod+Shift+6".action.move-column-to-workspace = 6;
            "Mod+Shift+7".action.move-column-to-workspace = 7;
            "Mod+Shift+8".action.move-column-to-workspace = 8;
            "Mod+Shift+9".action.move-column-to-workspace = 9;

            "Mod+BracketLeft".action.consume-or-expel-window-left = {};
            "Mod+BracketRight".action.consume-or-expel-window-right = {};
            "Mod+Comma".action.consume-window-into-column = {};
            "Mod+Period".action.expel-window-from-column = {};

            "Mod+R".action.switch-preset-column-width = {};
            "Mod+Shift+R".action.switch-preset-window-height = {};
            "Mod+Ctrl+R".action.reset-window-height = {};
            "Mod+F".action.maximize-column = {};
            "Mod+Ctrl+F".action.expand-column-to-available-width = {};
            "Mod+C".action.center-column = {};
            "Mod+Ctrl+C".action.center-visible-columns = {};
            "Mod+Minus".action.set-column-width = "-10%";
            "Mod+Equal".action.set-column-width = "+10%";
            "Mod+Shift+Minus".action.set-window-height = "-10%";
            "Mod+Shift+Equal".action.set-window-height = "+10%";

            "Mod+Shift+F".action.toggle-window-floating = {};
            "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = {};
            "Mod+W".action.toggle-column-tabbed-display = {};

            "Print".action.screenshot = {};
            "Ctrl+Print".action.screenshot-screen = {};
            "Alt+Print".action.screenshot-window = {};

            "Mod+Escape" = {
              allow-inhibiting = false;
              action.toggle-keyboard-shortcuts-inhibit = {};
            };
            "Mod+Shift+E".action.quit = {};
            "Mod+Shift+P".action.power-off-monitors = {};
          };
      };

      # Programs managed by home-manager (Stylix auto-themes these).
      rofi = {
        enable = true;
      };
      # Shell-replaceable; skipped when a desktop shell is active.
      swaylock = lib.mkIf (!shellEnabled) {
        enable = true;
      };
    };

    # Systemd user services — shell-replaceable services are gated;
    # playerctld (MPRIS) and XWayland remain unconditional.
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

    systemd = {
      user = {
        services =
          {
            # niri-flake can configure the path, but the actual XWayland bridge
            # still needs to be started explicitly in this repo.
            xwayland-satellite = {
              Unit = {
                Description = "XWayland bridge for Niri";
                PartOf = ["graphical-session.target"];
                After = ["graphical-session-pre.target"];
              };

              Service = {
                ExecStart = "${pkgs.xwayland-satellite}/bin/xwayland-satellite";
                Restart = "on-failure";
                RestartSec = 1;
              };

              Install = {
                WantedBy = ["graphical-session.target"];
              };
            };
          }
          // lib.optionalAttrs (!shellEnabled) {
            # Keep wallpaper and idle handling outside `spawn-at-startup` so
            # Home Manager can supervise them like the rest of the user session.
            swaybg = lib.mkIf (wallpaper != null) {
              Unit = {
                Description = "Wallpaper for Niri sessions";
                PartOf = ["graphical-session.target"];
                After = ["graphical-session-pre.target"];
              };

              Service = {
                ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
                Restart = "on-failure";
                RestartSec = 1;
              };

              Install = {
                WantedBy = ["graphical-session.target"];
              };
            };

            swayidle = {
              Unit = {
                Description = "Idle management for Niri sessions";
                PartOf = ["graphical-session.target"];
                After = ["graphical-session-pre.target"];
              };

              Service = {
                # 600s → lock screen, 660s → DPMS off, before-sleep → lock
                ExecStart = "${pkgs.swayidle}/bin/swayidle -w timeout 600 '${pkgs.swaylock}/bin/swaylock -f' timeout 660 '${niriBin} msg action power-off-monitors' before-sleep '${pkgs.swaylock}/bin/swaylock -f'";
                Restart = "on-failure";
                RestartSec = 1;
              };

              Install = {
                WantedBy = ["graphical-session.target"];
              };
            };
          };
      };
    };
  };
}
