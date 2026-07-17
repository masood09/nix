# Noctalia desktop shell (home-manager side, v5) — enables the HM module and
# declares its settings. The noctalia HM module is included via
# mkNixOSDesktopConfig (not in the shared home.nix); this file activates and
# configures it when desktop.shell == "noctalia".
#
# v5 is a ground-up rewrite of v4: the namespace is `programs.noctalia` (was
# `noctalia-shell`), config is `~/.config/noctalia/config.toml` (was
# settings.json), and the schema is entirely different (TOML, snake_case widget
# IDs, per-widget `[widget.<name>]` tables).
#
# Source of truth: this file is the ONLY source of truth for settings. Noctalia
# also keeps a writable `~/.local/state/noctalia/settings.toml` that the Settings
# UI writes to and which deep-merges *over* this config at runtime — so any tweak
# made in the GUI shadows what is declared here. To stay reproducible, make
# changes here (capture the desired values with `noctalia config export merged`),
# not in the UI, and clear the state overrides after deploying:
#   rm ~/.local/state/noctalia/settings.toml && noctalia msg config-reload
# Keys below were validated against the installed version's schema
# (`noctalia config export full`); config is also validated at build time
# (validateConfig). Unknown keys only warn; only a wrong value type fails.
#
# Theming: Stylix 26.05 has no v5 target, so we bridge the Stylix base16 palette
# into a Noctalia v5 *custom palette* (mirroring Stylix's own v4 noctalia-shell
# mapping) and select it via `theme.source = "custom"`, keeping the shell's
# colors identical to the desktop-wide Stylix palette.
{
  config,
  homelabCfg,
  lib,
  options,
  pkgs,
  ...
}: let
  # Guard against machines where the noctalia HM module is not imported
  # (servers, macOS). The flake wrapper is only included via
  # mkNixOSDesktopConfig, so the option namespace is absent elsewhere.
  hasNoctaliaOption = options.programs ? noctalia;
  shellIsNoctalia = hasNoctaliaOption && ((homelabCfg.desktop.shell or "none") == "noctalia") && pkgs.stdenv.isLinux;
  # Only render the Bluetooth bar widget on machines that actually expose
  # Bluetooth in the machine-level hardware profile; desktops without an
  # adapter should not show a dead control.
  bluetoothEnabled = homelabCfg.hardware.bluetooth.enable or false;

  stylixEnabled = config.stylix.enable or false;
  # Stylix base16 -> Noctalia palette roles. Mapping mirrors Stylix's v4
  # noctalia-shell target (modules/noctalia-shell/hm.nix upstream), so v5 lands
  # the exact colors the desktop had under v4. Lazily evaluated; only forced on
  # Stylix-enabled desktops (guarded by stylixEnabled below).
  stylixPalette = with config.lib.stylix.colors.withHashtag; {
    mPrimary = base0D;
    mOnPrimary = base00;
    mSecondary = base0E;
    mOnSecondary = base00;
    mTertiary = base0C;
    mOnTertiary = base00;
    mError = base08;
    mOnError = base00;
    mSurface = base00;
    mOnSurface = base05;
    mHover = base0C;
    mOnHover = base00;
    mSurfaceVariant = base01;
    mOnSurfaceVariant = base04;
    mOutline = base03;
    mShadow = base00;
  };
in {
  config = lib.mkIf shellIsNoctalia (lib.optionalAttrs hasNoctaliaOption {
    programs = {
      noctalia = {
        enable = true;

        # Custom palette bridged from Stylix. Writes ~/.config/noctalia/palettes/
        # stylix.json, selected by settings.theme below.
        customPalettes = lib.optionalAttrs stylixEnabled {
          stylix = {
            dark = stylixPalette;
          };
        };

        settings = {
          # Follow the Stylix palette via a custom palette; fall back to a
          # built-in scheme on any (hypothetical) non-Stylix desktop.
          theme =
            if stylixEnabled
            then {
              mode = "dark";
              source = "custom";
              custom_palette = "stylix";
            }
            else {
              mode = "dark";
              source = "builtin";
              builtin = "Gruvbox";
            };

          shell = {
            clipboard_enabled = true;
            polkit_agent = true;
            password_style = "random";
            animation = {
              enabled = true;
            };
            panel = {
              control_center_placement = "floating";
              control_center_position = "center";
            };
          };

          # Control Center dashboard (the panel, not the bar button).
          control_center = {
            hidden_tabs = ["calendar"];
            sidebar = "full";
            sidebar_section = "full";
          };

          bar = {
            main = {
              position = "top";
              background_opacity = 0.6;
              radius = 12;
              thickness = 40;
              margin_ends = 10;
              margin_edge = 10;
              concave_edge_corners = false;
              padding = 18;
              widget_spacing = 15;
              scale = 1.0;
              reserve_space = true;
              shadow = true;

              start = ["workspaces" "active_window" "media"];
              center = [];
              # Bluetooth only on machines with an adapter; clipboard next to tray.
              end =
                ["tray" "clipboard"]
                ++ lib.optional bluetoothEnabled "bluetooth"
                ++ ["battery" "volume" "brightness" "clock" "notifications" "control-center"];
            };
          };

          # Per-widget tweaks. Numeric fields are floats (schema types them as
          # doubles; a bare int would fail validation).
          widget = {
            workspaces = {
              display = "none";
            };
            active_window = {
              max_length = 500.0;
              title_scroll = "on_hover";
            };
            media = {
              max_length = 500.0;
              title_scroll = "on_hover";
              hide_when_no_media = true;
            };
            tray = {
              drawer = false;
            };
            battery = {
              display_mode = "glyph";
            };
            volume = {
              show_label = true;
            };
            brightness = {
              show_label = true;
            };
            clock = {
              format = "{:%a, %b %d %Y %H:%M}";
              tooltip_format = "{:%H:%M %a, %b %d}";
            };
            notifications = {
              hide_when_no_unread = false;
            };
            # Restore the NixOS logo on the Control Center bar button (v4 used the
            # distro logo). Points at noctalia's own bundled distro asset;
            # colorized (tinted to the theme accent) to match the current setup.
            "control-center" = {
              custom_image = "${config.programs.noctalia.package}/share/noctalia/assets/images/distros/nixos.svg";
              custom_image_colorize = true;
            };
          };

          # On-screen display (volume/brightness) centred at the bottom.
          osd = {
            position = "bottom_center";
            background_opacity = 0.6;
            offset_y = 40;
          };

          # Resolve location from IP (feeds weather / night light / auto theme).
          location = {
            auto_locate = true;
          };

          # Disable system-resource sampling (no sysmon widgets in use).
          system = {
            monitor = {
              enabled = false;
            };
          };

          # No dock.
          dock = {
            enabled = false;
          };

          # Idle policy: screen off at 10 min, lock 1 min later, suspend at 30 min,
          # with a surface-colour fade before an idle action fires.
          idle = {
            pre_action_fade_seconds = 5.0;
            behavior = {
              "screen-off" = {
                timeout = 600;
                action = "screen_off";
                enabled = true;
              };
              lock = {
                timeout = 660;
                action = "lock";
                enabled = true;
              };
              "lock-and-suspend" = {
                timeout = 1800;
                action = "suspend";
                enabled = true;
              };
            };
          };

          # NB: the active wallpaper is runtime state set via `noctalia msg
          # wallpaper-set`, not a config.toml key — so it is enforced
          # declaratively by the `noctalia-wallpaper` user service in
          # ./default.nix (which re-applies the Stylix image on each login),
          # not here.
        };
      };
    };
  });
}
