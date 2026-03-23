# Waybar module layout and configuration — adapted from sejjy/mechabar for niri.
# Hyprland modules replaced with niri equivalents; scripts replaced with inline commands.
{
  mainBar = {
    layer = "top";
    height = 0; # Auto-size based on font and padding
    spacing = 0;
    mode = "dock";
    reload_style_on_change = true;

    modules-left = [
      "custom/user"
      "custom/left_div#1"
      "niri/workspaces"
      "custom/right_div#1"
      "niri/window"
    ];

    modules-center = [
      "custom/left_div#2"
      "temperature"
      "custom/left_div#3"
      "memory"
      "custom/left_div#4"
      "cpu"
      "custom/left_inv#1"
      "custom/left_div#5"
      "custom/distro"
      "custom/right_div#2"
      "custom/right_inv#1"
      "idle_inhibitor"
      "clock#time"
      "custom/right_div#3"
      "clock#date"
      "custom/right_div#4"
      "network"
      "bluetooth"
      "custom/right_div#5"
    ];

    modules-right = [
      "tray"
      "mpris"
      "custom/left_div#6"
      "group/pulseaudio"
      "custom/left_div#7"
      "backlight"
      "custom/left_div#8"
      "battery"
      "custom/left_inv#2"
      "custom/power"
    ];

    # ---- Powerline dividers ----
    # Section-entry glyphs () and section-exit glyphs () create filled color
    # transitions between module backgrounds. Outline variants () / () produce
    # softer inner transitions (e.g. the cpu → distro accent island gap).

    "custom/left_div#1" = {
      format = "";
      tooltip = false;
    };
    "custom/left_div#2" = {
      format = "";
      tooltip = false;
    };
    "custom/left_div#3" = {
      format = "";
      tooltip = false;
    };
    "custom/left_div#4" = {
      format = "";
      tooltip = false;
    };
    "custom/left_div#5" = {
      format = "";
      tooltip = false;
    };
    "custom/left_div#6" = {
      format = "";
      tooltip = false;
    };
    "custom/left_div#7" = {
      format = "";
      tooltip = false;
    };
    "custom/left_div#8" = {
      format = "";
      tooltip = false;
    };
    "custom/left_inv#1" = {
      format = "";
      tooltip = false;
    };
    "custom/left_inv#2" = {
      format = "";
      tooltip = false;
    };

    "custom/right_div#1" = {
      format = "";
      tooltip = false;
    };
    "custom/right_div#2" = {
      format = "";
      tooltip = false;
    };
    "custom/right_div#3" = {
      format = "";
      tooltip = false;
    };
    "custom/right_div#4" = {
      format = "";
      tooltip = false;
    };
    "custom/right_div#5" = {
      format = "";
      tooltip = false;
    };
    "custom/right_inv#1" = {
      format = "";
      tooltip = false;
    };

    # ---- Custom modules ----

    "custom/user" = {
      format = "󰍜";
      min-length = 4;
      max-length = 4;
      tooltip-format = "niri";
    };

    "custom/distro" = {
      format = "󱄅"; # NixOS snowflake
      tooltip = false;
    };

    "custom/power" = {
      format = "󰤄";
      tooltip-format = "Power off monitors (Mod+Shift+P) · Quit niri (Mod+Shift+E)";
      on-click = "niri msg action power-off-monitors";
    };

    # ---- Niri workspaces ----

    "niri/workspaces" = {
      format = "{icon}";
      format-icons = {
        active = "●";
        default = "○";
      };
    };

    # ---- Active window title ----

    "niri/window" = {
      max-length = 50;
    };

    # ---- System stats ----

    temperature = {
      critical-threshold = 90;
      interval = 10;
      format = "{icon} {temperatureC}°C";
      format-critical = "󰀦 {temperatureC}°C";
      format-icons = ["󱃃" "󰔏" "󱃂"];
      min-length = 8;
      max-length = 8;
      tooltip-format = "Temperature: {temperatureF}°F";
    };

    memory = {
      interval = 10;
      format = "󰘚 {percentage}%";
      format-warning = "󰀧 {percentage}%";
      format-critical = "󰀧 {percentage}%";
      states = {
        warning = 75;
        critical = 90;
      };
      min-length = 7;
      max-length = 7;
      tooltip-format = "Memory used: {used:0.0f}/{total:0.0f} GiB";
    };

    cpu = {
      interval = 10;
      format = "󰍛 {usage}%";
      states = {
        warning = 75;
        critical = 90;
      };
      min-length = 7;
      max-length = 7;
      tooltip = false;
    };

    # ---- Idle inhibitor ----

    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "󰈈";
        deactivated = "󰈉";
      };
      min-length = 3;
      max-length = 3;
      tooltip-format-activated = "Idle inhibitor: on";
      tooltip-format-deactivated = "Idle inhibitor: off";
      start-activated = false;
    };

    # ---- Clock (split: time + date as separate modules) ----

    "clock#time" = {
      format = "{:%H:%M}";
      min-length = 5;
      max-length = 5;
      tooltip-format = "<b>Standard time</b>: {:%I:%M %p}";
    };

    "clock#date" = {
      format = "󰸗 {:%d-%m}";
      min-length = 8;
      max-length = 8;
      tooltip-format = "{calendar}";
      calendar = {
        mode = "month";
        mode-mon-col = 6;
        format = {
          months = "<span alpha='100%'><b>{}</b></span>";
          days = "<span alpha='90%'>{}</span>";
          weekdays = "<span alpha='80%'><i>{}</i></span>";
          today = "<span alpha='100%'><b><u>{}</u></b></span>";
        };
      };
      actions = {
        on-click = "mode";
      };
    };

    # ---- Network ----

    network = {
      interval = 10;
      format = "󰤨";
      format-ethernet = "󰈀";
      format-wifi = "{icon}";
      format-disconnected = "󰤯";
      format-disabled = "󰤮";
      format-icons = ["󰤟" "󰤢" "󰤥" "󰤨"];
      min-length = 2;
      max-length = 2;
      tooltip-format = "<b>Gateway</b>: {gwaddr}";
      tooltip-format-ethernet = "<b>Interface</b>: {ifname}\n<b>IP</b>: {ipaddr}";
      tooltip-format-wifi = "<b>Network</b>: {essid}\n<b>IP</b>: {ipaddr}/{cidr}\n<b>Strength</b>: {signalStrength}%";
      tooltip-format-disconnected = "Disconnected";
    };

    # ---- Bluetooth ----

    bluetooth = {
      format = "󰂯";
      format-disabled = "󰂲";
      format-off = "󰂲";
      format-on = "󰂰";
      format-connected = "󰂱";
      min-length = 2;
      max-length = 2;
      tooltip-format = "Bluetooth: {status}";
      tooltip-format-disabled = "Bluetooth disabled";
      tooltip-format-off = "Bluetooth off";
      tooltip-format-on = "Bluetooth disconnected";
      tooltip-format-connected = "Device: {device_alias}";
      tooltip-format-connected-battery = "Device: {device_alias}\nBattery: {device_battery_percentage}%";
    };

    # ---- System tray ----

    tray = {
      spacing = 8;
    };

    # ---- Media (MPRIS) ----

    mpris = {
      format = "{player_icon} {title} - {artist}";
      format-paused = "{status_icon} {title} - {artist}";
      tooltip-format = "Playing: {title} - {artist}";
      tooltip-format-paused = "Paused: {title} - {artist}";
      player-icons = {
        default = "󰐊";
      };
      status-icons = {
        paused = "󰏤";
      };
      max-length = 60;
    };

    # ---- Audio (grouped: output + microphone in a drawer) ----

    "group/pulseaudio" = {
      orientation = "horizontal";
      modules = ["pulseaudio#output" "pulseaudio#input"];
      drawer = {
        transition-left-to-right = false;
      };
    };

    "pulseaudio#output" = {
      format = "{icon} {volume}%";
      format-muted = "{icon} {volume}%";
      format-icons = {
        default = ["󰕿" "󰖀" "󰕾"];
        default-muted = "󰝟";
        headphone = "󰋋";
        headphone-muted = "󰟎";
        headset = "󰋎";
        headset-muted = "󰋐";
      };
      min-length = 7;
      max-length = 7;
      on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05+ -l 1.0";
      on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.05-";
      tooltip-format = "<b>Output</b>: {desc}";
    };

    "pulseaudio#input" = {
      format = "{format_source}";
      format-source = "󰍬 {volume}%";
      format-source-muted = "󰍭 {volume}%";
      min-length = 7;
      max-length = 7;
      on-click = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.05+";
      on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 0.05-";
      tooltip-format = "<b>Input</b>: {desc}";
    };

    # ---- Backlight ----

    backlight = {
      format = "{icon} {percent}%";
      format-icons = ["" "" "" "" "" "" "" "" ""];
      min-length = 7;
      max-length = 7;
      on-scroll-up = "brightnessctl set +5%";
      on-scroll-down = "brightnessctl set 5%-";
      tooltip-format = "Screen brightness";
    };

    # ---- Battery ----

    battery = {
      states = {
        warning = 20;
        critical = 10;
      };
      format = "{icon} {capacity}%";
      format-time = "{H}h {M}min";
      format-icons = ["󰂎" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      format-charging = "󰉁 {capacity}%";
      min-length = 7;
      max-length = 7;
      tooltip-format = "<b>Discharging</b>: {time}";
      tooltip-format-charging = "<b>Charging</b>: {time}";
    };
  };
}
