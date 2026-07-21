# Niri keybindings — the `programs.niri.settings.binds` value.
# Not a Home Manager module: a plain function returning an attrset, imported by
# ./default.nix.
#
# Compositor-native binds. Keep the launcher on Mod+D regardless of the selected
# desktop shell; shell-owned lock bindings stay conditional. Lid-close locking is
# handled separately by the user services in ./default.nix.
#
# Three-way key dispatch (see the module header in ./default.nix for the full
# rationale):
#   shell="none"     → swaylock lock, wpctl/playerctl/light direct CLI
#   shell="noctalia" → noctalia msg IPC for lock + hardware controls
#   shell=<other>    → no lock bind; media/brightness still direct CLI
{
  homelabCfg,
  lib,
  shellEnabled,
  shellIsNoctalia,
  ...
}:
lib.optionalAttrs (!shellEnabled) {
  "Super+Alt+L" = {
    action = {spawn = ["swaylock"];};
  };
}
# Vendor hardware keys that should only exist when Noctalia owns the
# corresponding desktop surface. Future shells must opt in explicitly.
// lib.optionalAttrs shellIsNoctalia {
  "Super+Alt+L" = {
    allow-when-locked = true;
    action = {spawn = ["noctalia" "msg" "session" "lock"];};
  };
  # Toggle the Noctalia clipboard-history panel. Not allowed when
  # locked — it would expose clipboard contents.
  "Super+Alt+C" = {
    action = {spawn = ["noctalia" "msg" "panel-toggle" "clipboard"];};
  };
  "XF86WLAN" = {
    allow-when-locked = true;
    action = {spawn = ["noctalia" "msg" "wifi-toggle"];};
  };
  "XF86Bluetooth" = {
    allow-when-locked = true;
    action = {spawn = ["noctalia" "msg" "bluetooth-toggle"];};
  };
  # Fn+F7 on ThinkPads — repurposed as a secondary lock trigger
  "XF86Display" = {
    allow-when-locked = true;
    action = {spawn = ["noctalia" "msg" "session" "lock"];};
  };
  # Fn+F11 on ThinkPads — cycles through power profiles via Noctalia
  "XF86Keyboard" = {
    allow-when-locked = true;
    action = {spawn = ["noctalia" "msg" "power-cycle"];};
  };
  # Fn+F9 on ThinkPads — opens/closes the Noctalia settings panel
  "XF86Tools" = {
    allow-when-locked = true;
    action = {spawn = ["noctalia" "msg" "settings-toggle"];};
  };
}
// {
  "Mod+D" = {
    action = {spawn = ["rofi" "-show" "drun"];};
  };
  # Mirrors Mod+D — some ThinkPads emit XF86Favorites from Fn+F12
  "XF86Favorites" = {
    action = {spawn = ["rofi" "-show" "drun"];};
  };
  "Mod+Shift+Slash" = {action = {show-hotkey-overlay = {};};};

  "Mod+Return" = {
    action = {spawn = ["kitty"];};
  };
  "Super+B" = {
    action = {spawn = ["zen-beta"];};
  };
}
// lib.optionalAttrs (homelabCfg.programs.emacs.enable or false) {
  # Connects to the Emacs daemon started in spawn-at-startup.
  "Mod+E" = {
    action = {spawn = ["emacsclient" "-c"];};
  };
}
// {
  # Orca screen reader — toggle on/off with a single key.
  "Super+Alt+S" = {
    allow-when-locked = true;
    action = {spawn-sh = "pkill orca || exec orca";};
  };

  # Media and brightness keys prefer Noctalia IPC when available so
  # the shell drives its own OSD/state, but retain the direct CLI
  # fallbacks for shell="none" and any future non-Noctalia shell.
  # The else branch uses action.spawn with ["sh" "-c" ...] instead
  # of action.spawn-sh so both arms share the same attribute key.
  "XF86AudioRaiseVolume" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "volume-up"]
        else ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0"];
    };
  };
  "XF86AudioLowerVolume" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "volume-down"]
        else ["sh" "-c" "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-"];
    };
  };
  "XF86AudioMute" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "volume-mute"]
        else ["sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"];
    };
  };
  "XF86AudioMicMute" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "mic-mute"]
        else ["sh" "-c" "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"];
    };
  };

  "XF86AudioPlay" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "media" "toggle"]
        else ["sh" "-c" "playerctl play-pause"];
    };
  };
  "XF86AudioStop" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "media" "stop"]
        else ["sh" "-c" "playerctl stop"];
    };
  };
  "XF86AudioPrev" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "media" "previous"]
        else ["sh" "-c" "playerctl previous"];
    };
  };
  "XF86AudioNext" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "media" "next"]
        else ["sh" "-c" "playerctl next"];
    };
  };

  "XF86MonBrightnessUp" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "brightness-up"]
        else ["brightnessctl" "set" "10%+"];
    };
  };
  "XF86MonBrightnessDown" = {
    allow-when-locked = true;
    action = {
      spawn =
        if shellIsNoctalia
        then ["noctalia" "msg" "brightness-down"]
        else ["brightnessctl" "set" "10%-"];
    };
  };

  "Mod+O" = {
    repeat = false;
    action = {toggle-overview = {};};
  };
  "Mod+Q" = {
    repeat = false;
    action = {close-window = {};};
  };

  # — Navigation (arrow keys + vim hjkl) —
  # Primary navigation stays local first, but falls through to the
  # adjacent monitor/workspace at the edge so directional movement
  # does not dead-end on the current container.
  "Mod+Left" = {action = {focus-column-or-monitor-left = {};};};
  "Mod+Down" = {action = {focus-window-or-workspace-down = {};};};
  "Mod+Up" = {action = {focus-window-or-workspace-up = {};};};
  "Mod+Right" = {action = {focus-column-or-monitor-right = {};};};
  "Mod+H" = {action = {focus-column-or-monitor-left = {};};};
  "Mod+J" = {action = {focus-window-or-workspace-down = {};};};
  "Mod+K" = {action = {focus-window-or-workspace-up = {};};};
  "Mod+L" = {action = {focus-column-or-monitor-right = {};};};

  # Shift keeps the same fallback semantics while moving the focused
  # column/window instead of only changing focus.
  "Mod+Shift+Left" = {action = {move-column-left-or-to-monitor-left = {};};};
  "Mod+Shift+Down" = {action = {move-window-down-or-to-workspace-down = {};};};
  "Mod+Shift+Up" = {action = {move-window-up-or-to-workspace-up = {};};};
  "Mod+Shift+Right" = {action = {move-column-right-or-to-monitor-right = {};};};
  "Mod+Shift+H" = {action = {move-column-left-or-to-monitor-left = {};};};
  "Mod+Shift+J" = {action = {move-window-down-or-to-workspace-down = {};};};
  "Mod+Shift+K" = {action = {move-window-up-or-to-workspace-up = {};};};
  "Mod+Shift+L" = {action = {move-column-right-or-to-monitor-right = {};};};

  "Mod+Home" = {action = {focus-column-first = {};};};
  "Mod+End" = {action = {focus-column-last = {};};};
  "Mod+Ctrl+Home" = {action = {move-column-to-first = {};};};
  "Mod+Ctrl+End" = {action = {move-column-to-last = {};};};

  # Ctrl variants remain explicit monitor-to-monitor navigation and
  # bypass the local-first fallback behavior above.
  "Mod+Ctrl+Left" = {action = {focus-monitor-left = {};};};
  "Mod+Ctrl+Down" = {action = {focus-monitor-down = {};};};
  "Mod+Ctrl+Up" = {action = {focus-monitor-up = {};};};
  "Mod+Ctrl+Right" = {action = {focus-monitor-right = {};};};
  "Mod+Ctrl+H" = {action = {focus-monitor-left = {};};};
  "Mod+Ctrl+J" = {action = {focus-monitor-down = {};};};
  "Mod+Ctrl+K" = {action = {focus-monitor-up = {};};};
  "Mod+Ctrl+L" = {action = {focus-monitor-right = {};};};

  # Shift+Ctrl moves the entire column to a specific monitor
  # (no local-first fallback — always crosses monitor boundary).
  "Mod+Shift+Ctrl+Left" = {action = {move-column-to-monitor-left = {};};};
  "Mod+Shift+Ctrl+Down" = {action = {move-column-to-monitor-down = {};};};
  "Mod+Shift+Ctrl+Up" = {action = {move-column-to-monitor-up = {};};};
  "Mod+Shift+Ctrl+Right" = {action = {move-column-to-monitor-right = {};};};
  "Mod+Shift+Ctrl+H" = {action = {move-column-to-monitor-left = {};};};
  "Mod+Shift+Ctrl+J" = {action = {move-column-to-monitor-down = {};};};
  "Mod+Shift+Ctrl+K" = {action = {move-column-to-monitor-up = {};};};
  "Mod+Shift+Ctrl+L" = {action = {move-column-to-monitor-right = {};};};

  "Mod+Page_Down" = {action = {focus-workspace-down = {};};};
  "Mod+Page_Up" = {action = {focus-workspace-up = {};};};
  "Mod+U" = {action = {focus-workspace-down = {};};};
  "Mod+I" = {action = {focus-workspace-up = {};};};
  "Mod+Ctrl+Page_Down" = {action = {move-column-to-workspace-down = {};};};
  "Mod+Ctrl+Page_Up" = {action = {move-column-to-workspace-up = {};};};
  "Mod+Ctrl+U" = {action = {move-column-to-workspace-down = {};};};
  "Mod+Ctrl+I" = {action = {move-column-to-workspace-up = {};};};

  "Mod+Shift+Page_Down" = {action = {move-workspace-down = {};};};
  "Mod+Shift+Page_Up" = {action = {move-workspace-up = {};};};
  "Mod+Shift+U" = {action = {move-workspace-down = {};};};
  "Mod+Shift+I" = {action = {move-workspace-up = {};};};

  "Mod+WheelScrollDown" = {
    cooldown-ms = 150;
    action = {focus-workspace-down = {};};
  };
  "Mod+WheelScrollUp" = {
    cooldown-ms = 150;
    action = {focus-workspace-up = {};};
  };
  "Mod+Ctrl+WheelScrollDown" = {
    cooldown-ms = 150;
    action = {move-column-to-workspace-down = {};};
  };
  "Mod+Ctrl+WheelScrollUp" = {
    cooldown-ms = 150;
    action = {move-column-to-workspace-up = {};};
  };
  "Mod+WheelScrollRight" = {action = {focus-column-right = {};};};
  "Mod+WheelScrollLeft" = {action = {focus-column-left = {};};};
  "Mod+Ctrl+WheelScrollRight" = {action = {move-column-right = {};};};
  "Mod+Ctrl+WheelScrollLeft" = {action = {move-column-left = {};};};
  "Mod+Shift+WheelScrollDown" = {action = {focus-column-right = {};};};
  "Mod+Shift+WheelScrollUp" = {action = {focus-column-left = {};};};
  "Mod+Ctrl+Shift+WheelScrollDown" = {action = {move-column-right = {};};};
  "Mod+Ctrl+Shift+WheelScrollUp" = {action = {move-column-left = {};};};

  "Mod+1" = {action = {focus-workspace = 1;};};
  "Mod+2" = {action = {focus-workspace = 2;};};
  "Mod+3" = {action = {focus-workspace = 3;};};
  "Mod+4" = {action = {focus-workspace = 4;};};
  "Mod+5" = {action = {focus-workspace = 5;};};
  "Mod+6" = {action = {focus-workspace = 6;};};
  "Mod+7" = {action = {focus-workspace = 7;};};
  "Mod+8" = {action = {focus-workspace = 8;};};
  "Mod+9" = {action = {focus-workspace = 9;};};

  "Mod+Shift+1" = {action = {move-column-to-workspace = 1;};};
  "Mod+Shift+2" = {action = {move-column-to-workspace = 2;};};
  "Mod+Shift+3" = {action = {move-column-to-workspace = 3;};};
  "Mod+Shift+4" = {action = {move-column-to-workspace = 4;};};
  "Mod+Shift+5" = {action = {move-column-to-workspace = 5;};};
  "Mod+Shift+6" = {action = {move-column-to-workspace = 6;};};
  "Mod+Shift+7" = {action = {move-column-to-workspace = 7;};};
  "Mod+Shift+8" = {action = {move-column-to-workspace = 8;};};
  "Mod+Shift+9" = {action = {move-column-to-workspace = 9;};};

  "Mod+BracketLeft" = {action = {consume-or-expel-window-left = {};};};
  "Mod+BracketRight" = {action = {consume-or-expel-window-right = {};};};
  "Mod+Comma" = {action = {consume-window-into-column = {};};};
  "Mod+Period" = {action = {expel-window-from-column = {};};};

  "Mod+R" = {action = {switch-preset-column-width = {};};};
  "Mod+Shift+R" = {action = {switch-preset-window-height = {};};};
  "Mod+Ctrl+R" = {action = {reset-window-height = {};};};
  "Mod+F" = {action = {maximize-column = {};};};
  "Mod+Ctrl+F" = {action = {expand-column-to-available-width = {};};};
  "Mod+C" = {action = {center-column = {};};};
  "Mod+Ctrl+C" = {action = {center-visible-columns = {};};};
  "Mod+Minus" = {action = {set-column-width = "-10%";};};
  "Mod+Equal" = {action = {set-column-width = "+10%";};};
  "Mod+Shift+Minus" = {action = {set-window-height = "-10%";};};
  "Mod+Shift+Equal" = {action = {set-window-height = "+10%";};};

  "Mod+Shift+F" = {action = {toggle-window-floating = {};};};
  "Mod+Shift+V" = {action = {switch-focus-between-floating-and-tiling = {};};};
  "Mod+W" = {action = {toggle-column-tabbed-display = {};};};

  "Print" = {action = {screenshot = {};};};
  "Ctrl+Print" = {action = {screenshot-screen = {};};};
  "Alt+Print" = {action = {screenshot-window = {};};};

  "Mod+Escape" = {
    allow-inhibiting = false;
    action = {toggle-keyboard-shortcuts-inhibit = {};};
  };
  "Mod+Shift+E" = {action = {quit = {};};};
  "Mod+Shift+P" = {action = {power-off-monitors = {};};};
}
