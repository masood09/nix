# Niri settings — declarative configuration for niri compositor
{scripts}: {
  # Input configuration
  input = {
    keyboard = {
      xkb = {
        layout = "us";
        options = "grp:win_space_toggle,compose:ralt,ctrl:nocaps";
      };
      track-layout = "global";
    };

    touchpad = {
      tap = true;
      natural-scroll = true;
    };

    warp-mouse-to-focus.enable = true;
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "0%";
    };
  };

  # Output configuration
  outputs = {
    "eDP-1" = {
      mode = {
        width = 1920;
        height = 1080;
        refresh = 59.999;
      };
      scale = 1.25;
      position = {
        x = 1280;
        y = 0;
      };
    };
  };

  # Layout settings
  layout = {
    gaps = 8;
    center-focused-column = "never";

    preset-column-widths = [
      {proportion = 0.33333;}
      {proportion = 0.5;}
      {proportion = 0.66667;}
    ];

    default-column-width = {proportion = 0.5;};

    focus-ring = {
      enable = true;
      width = 2;
      active.color = "#7fc8ff";
      inactive.color = "#505050";
    };

    border = {
      enable = false;
      width = 4;
      active.color = "#ffc87f";
      inactive.color = "#505050";
    };
  };

  # Prefer no client-side decorations
  prefer-no-csd = true;

  # Screenshot path
  screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

  # Hotkey overlay
  hotkey-overlay.skip-at-startup = true;

  # Window rules
  window-rules = [
    # WezTerm workaround
    {
      matches = [{app-id = "^org\\.wezfurlong\\.wezterm$";}];
      default-column-width = {};
    }
    # Firefox picture-in-picture
    {
      matches = [
        {
          app-id = "firefox$";
          title = "^Picture-in-Picture$";
        }
      ];
      open-floating = true;
    }
  ];

  # Keybindings
  binds = let
    # Helper to create spawn actions
    spawn = cmd: {action.spawn = [cmd];};
    spawn-sh = cmd: {action.spawn = ["sh" "-c" cmd];};
  in {
    # Show hotkey overlay
    "Mod+Shift+Slash".action.show-hotkey-overlay = {};

    # Application launchers
    "Mod+Return" = spawn "kitty";
    "Mod+B".action.spawn = ["${scripts.run-or-raise-zen}"];
    "Mod+E".action.spawn = ["${scripts.run-or-raise-emacs}"];
    "Mod+D" = spawn "fuzzel";
    "Super+Alt+L" = spawn "swaylock";

    # Screen reader toggle
    "Super+Alt+S".action.spawn = ["sh" "-c" "pkill orca || exec orca"];

    # Volume controls
    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn = ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"];
    };
    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn = ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"];
    };
    "XF86AudioMute" = {
      allow-when-locked = true;
      action.spawn = ["sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"];
    };
    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action.spawn = ["sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"];
    };

    # Media controls
    "XF86AudioPlay".allow-when-locked = true;
    "XF86AudioPlay".action.spawn = ["sh" "-c" "playerctl play-pause"];
    "XF86AudioStop".allow-when-locked = true;
    "XF86AudioStop".action.spawn = ["sh" "-c" "playerctl stop"];
    "XF86AudioPrev".allow-when-locked = true;
    "XF86AudioPrev".action.spawn = ["sh" "-c" "playerctl previous"];
    "XF86AudioNext".allow-when-locked = true;
    "XF86AudioNext".action.spawn = ["sh" "-c" "playerctl next"];

    # Brightness controls
    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn = ["brightnessctl" "--class=backlight" "set" "+10%"];
    };
    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn = ["brightnessctl" "--class=backlight" "set" "10%-"];
    };

    # Overview
    "Mod+O".action.toggle-overview = {};

    # Window management
    "Mod+Q".action.close-window = {};

    # Focus navigation (arrows)
    "Mod+Left".action.focus-column-left = {};
    "Mod+Down".action.focus-window-down = {};
    "Mod+Up".action.focus-window-up = {};
    "Mod+Right".action.focus-column-right = {};

    # Focus navigation (vim keys)
    "Mod+H".action.focus-column-left = {};
    "Mod+J".action.focus-window-down = {};
    "Mod+K".action.focus-window-up = {};
    "Mod+L".action.focus-column-right = {};

    # Move windows (arrows)
    "Mod+Ctrl+Left".action.move-column-left = {};
    "Mod+Ctrl+Down".action.move-window-down = {};
    "Mod+Ctrl+Up".action.move-window-up = {};
    "Mod+Ctrl+Right".action.move-column-right = {};

    # Move windows (vim keys)
    "Mod+Ctrl+H".action.move-column-left = {};
    "Mod+Ctrl+J".action.move-window-down = {};
    "Mod+Ctrl+K".action.move-window-up = {};
    "Mod+Ctrl+L".action.move-column-right = {};

    # Column navigation
    "Mod+Home".action.focus-column-first = {};
    "Mod+End".action.focus-column-last = {};
    "Mod+Ctrl+Home".action.move-column-to-first = {};
    "Mod+Ctrl+End".action.move-column-to-last = {};

    # Monitor focus (arrows)
    "Mod+Shift+Left".action.focus-monitor-left = {};
    "Mod+Shift+Down".action.focus-monitor-down = {};
    "Mod+Shift+Up".action.focus-monitor-up = {};
    "Mod+Shift+Right".action.focus-monitor-right = {};

    # Monitor focus (vim keys)
    "Mod+Shift+H".action.focus-monitor-left = {};
    "Mod+Shift+J".action.focus-monitor-down = {};
    "Mod+Shift+K".action.focus-monitor-up = {};
    "Mod+Shift+L".action.focus-monitor-right = {};

    # Move to monitor (arrows)
    "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = {};
    "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = {};
    "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = {};
    "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = {};

    # Move to monitor (vim keys)
    "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = {};
    "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = {};
    "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = {};
    "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = {};

    # Workspace navigation
    "Mod+Page_Down".action.focus-workspace-down = {};
    "Mod+Page_Up".action.focus-workspace-up = {};
    "Mod+U".action.focus-workspace-down = {};
    "Mod+I".action.focus-workspace-up = {};
    "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = {};
    "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = {};
    "Mod+Ctrl+U".action.move-column-to-workspace-down = {};
    "Mod+Ctrl+I".action.move-column-to-workspace-up = {};

    # Move workspaces
    "Mod+Shift+Page_Down".action.move-workspace-down = {};
    "Mod+Shift+Page_Up".action.move-workspace-up = {};
    "Mod+Shift+U".action.move-workspace-down = {};
    "Mod+Shift+I".action.move-workspace-up = {};

    # Workspace by number
    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;
    "Mod+Ctrl+1".action.move-column-to-workspace = 1;
    "Mod+Ctrl+2".action.move-column-to-workspace = 2;
    "Mod+Ctrl+3".action.move-column-to-workspace = 3;
    "Mod+Ctrl+4".action.move-column-to-workspace = 4;
    "Mod+Ctrl+5".action.move-column-to-workspace = 5;
    "Mod+Ctrl+6".action.move-column-to-workspace = 6;
    "Mod+Ctrl+7".action.move-column-to-workspace = 7;
    "Mod+Ctrl+8".action.move-column-to-workspace = 8;
    "Mod+Ctrl+9".action.move-column-to-workspace = 9;

    # Column management
    "Mod+BracketLeft".action.consume-or-expel-window-left = {};
    "Mod+BracketRight".action.consume-or-expel-window-right = {};
    "Mod+Comma".action.consume-window-into-column = {};
    "Mod+Period".action.expel-window-from-column = {};

    # Window sizing
    "Mod+R".action.switch-preset-column-width = {};
    "Mod+Shift+R".action.switch-preset-window-height = {};
    "Mod+Ctrl+R".action.reset-window-height = {};
    "Mod+F".action.maximize-column = {};
    "Mod+Shift+F".action.fullscreen-window = {};
    "Mod+Ctrl+F".action.expand-column-to-available-width = {};
    "Mod+C".action.center-column = {};
    "Mod+Ctrl+C".action.center-visible-columns = {};
    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Equal".action.set-column-width = "+10%";
    "Mod+Shift+Minus".action.set-window-height = "-10%";
    "Mod+Shift+Equal".action.set-window-height = "+10%";

    # Floating toggle
    "Mod+V".action.toggle-window-floating = {};
    "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = {};

    # Tabbed display
    "Mod+W".action.toggle-column-tabbed-display = {};

    # Screenshots
    "Print".action.screenshot = {};
    "Ctrl+Print".action.screenshot-screen = {};
    "Alt+Print".action.screenshot-window = {};

    # System
    "Mod+Escape" = {
      allow-inhibiting = false;
      action.toggle-keyboard-shortcuts-inhibit = {};
    };
    "Mod+Shift+E".action.quit = {};
    "Ctrl+Alt+Delete".action.quit = {};
    "Mod+Shift+P".action.power-off-monitors = {};

    # Mouse wheel workspace navigation
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

    # Mouse wheel column navigation
    "Mod+WheelScrollRight".action.focus-column-right = {};
    "Mod+WheelScrollLeft".action.focus-column-left = {};
    "Mod+Ctrl+WheelScrollRight".action.move-column-right = {};
    "Mod+Ctrl+WheelScrollLeft".action.move-column-left = {};
    "Mod+Shift+WheelScrollDown".action.focus-column-right = {};
    "Mod+Shift+WheelScrollUp".action.focus-column-left = {};
    "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = {};
    "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = {};
  };
}
