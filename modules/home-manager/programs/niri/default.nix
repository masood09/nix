# Niri desktop (home-manager side) — compositor config plus Wayland helpers.
# Niri itself is configured declaratively through niri-flake's HM module so
# Stylix can theme it; surrounding desktop helpers stay split by desktop.shell.
# Backlight control (light) is system-level — see modules/nixos/desktop/_niri.nix.
#
# File layout: the bulk `programs.niri.settings` sections live in siblings —
# _binds.nix, _layout.nix, _animations.nix, _window-rules.nix. Those are plain
# functions returning values, NOT Home Manager modules: they are pulled in with
# `import` (see niriArgs below), never added to `imports`, so everything stays
# under this module's single niriEnabled/hasNiriOption guard. _noctalia.nix and
# _waybar.nix, by contrast, ARE modules and do live in `imports`.
#
# Input tuning: keyboard repeat-delay/repeat-rate are tuned to match Darwin's
# NSGlobalDomain.{InitialKeyRepeat,KeyRepeat} from modules/macos/base.nix so the
# typing feel is consistent across the laptop fleet. See the input.keyboard
# block below for the tick-to-ms/Hz conversion.
#
# Shell guard: when homelab.desktop.shell != "none", shell-replaceable programs
# (swaybg, swaync, swaylock, udiskie) are skipped — the desktop shell provides
# equivalent UI. swayidle is the exception: it remains installed because both
# shell and non-shell sessions use it for session-side before-sleep locking.
# Rofi remains enabled regardless so the compositor-level launcher key stays
# consistent across shell choices. Compositor-level utilities
# (wl-clipboard, xwayland-satellite), swayidle, and playerctld remain
# unconditional.
#
# Noctalia IPC dispatch: hardware keys (volume, mute, media, brightness) and
# vendor function keys (Wi-Fi, Bluetooth, lock, power-profile, settings) are
# routed through `noctalia msg …` when desktop.shell == "noctalia"
# so the shell owns its OSD and internal state. Noctalia also uses a small
# swayidle helper so lid-close suspend locks from the user session before
# logind freezes user.slice. Non-Noctalia shells fall back to direct CLI tools
# (wpctl, playerctl, light, swaylock). The routing is intentionally keyed on
# shellIsNoctalia, not shellEnabled, so future shells do not silently inherit
# Noctalia-specific IPC commands.
{
  config,
  homelabCfg,
  lib,
  options,
  pkgs,
  ...
}: let
  # This module is imported for every HM user, including nix-darwin users.
  # Darwin does not expose Home Manager's `programs.niri` option namespace, so
  # any unconditional write to that subtree fails during module evaluation even
  # if the config is wrapped in `mkIf false`.
  hasNiriOption = options.programs ? niri;
  niriEnabled = hasNiriOption && (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
  # true when a desktop shell (e.g. Noctalia) replaces shell-owned desktop UI
  # such as the bar, notifications, lock screen, wallpaper, and idle timeouts.
  # swayidle stays unconditional — the shell replaces timeout policy but every
  # session still needs a user-side before-sleep hook.
  shellEnabled = (homelabCfg.desktop.shell or "none") != "none";
  # Keep Noctalia IPC routing explicit so future shells do not accidentally
  # inherit commands that only Noctalia implements.
  shellIsNoctalia = (homelabCfg.desktop.shell or "none") == "noctalia";
  stylixEnabled = config.stylix.enable or false;
  wallpaper =
    if stylixEnabled
    then (config.stylix.image or null)
    else null;
  niriBin =
    if hasNiriOption
    then "${config.programs.niri.package}/bin/niri"
    else null;
  # Use the Home Manager package path directly so user services don't depend on
  # PATH or /run/current-system. Guarded: the noctalia HM module is only
  # included via mkNixOSDesktopConfig, so the option is absent on servers.
  hasNoctaliaOption = options.programs ? noctalia;
  noctaliaBin =
    if hasNoctaliaOption
    then lib.getExe config.programs.noctalia.package
    else null;

  # Bulk `programs.niri.settings` sections live in sibling files to keep this
  # module readable. They are plain functions returning values — NOT Home
  # Manager modules — so they are pulled in with `import`, not `imports`, and
  # stay inside this module's single `niriEnabled` / `hasNiriOption` guard.
  # Each takes what it needs from this arg set and ignores the rest.
  niriArgs = {
    inherit config homelabCfg lib pkgs shellEnabled shellIsNoctalia stylixEnabled;
  };
in {
  imports = [
    ./_noctalia.nix
    ./_waybar.nix
  ];

  config = lib.mkIf niriEnabled {
    home = {
      # Packages without home-manager modules — compositor utilities are always
      # installed. swayidle is unconditional because both the plain Niri setup
      # and the Noctalia shell use it for session-side before-sleep locking.
      # Shell-replaceable packages such as swaybg remain conditional.
      packages = with pkgs;
        [
          wl-clipboard # clipboard utilities (no HM module)
          xwayland-satellite # XWayland support for niri (started as a user service)
          swayidle # before-sleep hook for lock-before-suspend
        ]
        ++ lib.optionals (!shellEnabled) [
          swaybg # wallpaper helper (started as a user service)
        ];
    };

    programs =
      {
        # Programs managed by home-manager (Stylix auto-themes these).
        rofi = {
          enable = true;
        };
        # Shell-replaceable; skipped when a desktop shell is active.
        swaylock = lib.mkIf (!shellEnabled) {
          enable = true;
        };
      }
      // lib.optionalAttrs hasNiriOption {
        # Keep the `programs.niri` subtree absent on platforms where the
        # upstream HM module was never imported (notably nix-darwin).
        # Use the nixpkgs niri binary instead of the flake's own build so the
        # compositor tracks the same release cadence as the rest of the system.
        niri = {
          package = pkgs.niri;
          settings = {
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
              # Qt platform theme is managed by Stylix's qt target (qtct +
              # Kvantum). Setting QT_QPA_PLATFORMTHEME here would override
              # home.sessionVariables and break Kvantum for QML apps.
              ELECTRON_OZONE_PLATFORM_HINT = "auto";
              NIXOS_OZONE_WL = "1";
            };

            # Session-startup processes launched alongside the compositor.
            # Noctalia is first so the shell owns OSD/notifications before apps
            # appear. Desktop apps follow, each gated on its own enable flag so
            # server and headless closures stay free of GUI packages.
            # Emacs starts as a daemon; the matching Mod+E keybinding opens a
            # graphical client frame via emacsclient.
            spawn-at-startup =
              lib.optionals shellIsNoctalia [
                {
                  command = ["noctalia"];
                }
              ]
              ++ lib.optional (homelabCfg.role == "desktop") {command = ["bitwarden"];}
              ++ lib.optional (homelabCfg.programs.element-desktop.enable or false) {command = ["element-desktop"];}
              ++ lib.optional (homelabCfg.programs.emacs.enable or false) {command = ["emacs" "--daemon"];};

            gestures = {
              hot-corners = {
                enable = false;
              };
            };

            input = {
              keyboard = {
                xkb = {
                  options = "caps:escape";
                };
                numlock = true;
                # Keyboard repeat — kept in sync with Darwin
                # (modules/macos/base.nix NSGlobalDomain.{InitialKeyRepeat,KeyRepeat})
                # so typing feel matches across Linux desktops and macOS laptops.
                # Darwin units are 15ms ticks: InitialKeyRepeat=15 → 15×15=225ms,
                # KeyRepeat=2 → 2×15=30ms ≈ 33Hz. Niri (libinput) uses ms + Hz directly.
                # If you change one side, change the other.
                repeat-delay = 225;
                repeat-rate = 33;
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

            layout = import ./_layout.nix niriArgs;

            overview = {
              workspace-shadow = {
                enable = false;
              };
            };

            hotkey-overlay = {
              skip-at-startup = true;
            };
            prefer-no-csd = true;
            screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

            animations = import ./_animations.nix niriArgs;

            window-rules = import ./_window-rules.nix niriArgs;

            # Work around clients that send XDG activation tokens with an invalid
            # serial — without this, focus-stealing prevention rejects them silently.
            debug = {
              honor-xdg-activation-with-invalid-serial = [];
            };

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
                transform = {
                  rotation = 0;
                };
                position = {
                  x = 0;
                  y = 0;
                };
              };
            };

            binds = import ./_binds.nix niriArgs;
          };
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
          // lib.optionalAttrs shellIsNoctalia {
            # Runs swayidle purely as a before-sleep hook so the Noctalia lock
            # screen activates while the user session is still alive. The `-w`
            # flag holds logind's sleep inhibitor until the lock command exits,
            # preventing suspend from racing ahead of the lock paint.
            noctalia-before-sleep-lock = {
              Unit = {
                Description = "Lock Noctalia before system sleep";
                PartOf = ["graphical-session.target"];
                After = ["graphical-session-pre.target"];
                # Keep the existing helper running during `sd-switch` so deploys
                # do not bounce the service and trigger an unexpected lock.
                X-SwitchMethod = "keep-old";
              };

              Service = {
                ExecStart = "${pkgs.swayidle}/bin/swayidle -w before-sleep '${noctaliaBin} msg session lock'";
                Restart = "on-failure";
                RestartSec = 1;
              };

              Install = {
                WantedBy = ["graphical-session.target"];
              };
            };
          }
          // lib.optionalAttrs (shellIsNoctalia && wallpaper != null) {
            # The Noctalia wallpaper is runtime state (set via `noctalia msg
            # wallpaper-set`), not a config.toml key, so enforce it declaratively:
            # re-apply the Stylix image on each login. Noctalia is spawned by niri
            # (not a systemd unit), so poll its IPC until it is up. Idempotent.
            noctalia-wallpaper = {
              Unit = {
                Description = "Apply the Noctalia wallpaper (Stylix image)";
                PartOf = ["graphical-session.target"];
                After = ["graphical-session.target"];
              };

              Service = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = pkgs.writeShellScript "noctalia-set-wallpaper" ''
                  for _ in $(seq 1 60); do
                    if ${noctaliaBin} msg wallpaper-set ${wallpaper} 2>/dev/null; then
                      exit 0
                    fi
                    sleep 1
                  done
                  exit 0
                '';
              };

              Install = {
                WantedBy = ["graphical-session.target"];
              };
            };
          }
          // lib.optionalAttrs (!shellEnabled) {
            # Targets systemd lock.target so `loginctl lock-session` triggers
            # swaylock. Type=forking + `-f` lets swaylock daemonise and report
            # readiness once the lock surface is painted.
            swaylock = {
              Unit = {
                Description = "Lock the session with swaylock";
                PartOf = ["lock.target"];
                Before = ["lock.target"];
              };

              Service = {
                Type = "forking";
                ExecStart = "${pkgs.swaylock}/bin/swaylock -f";
                Restart = "on-failure";
                RestartSec = 0;
              };

              Install = {
                WantedBy = ["lock.target"];
              };
            };

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
