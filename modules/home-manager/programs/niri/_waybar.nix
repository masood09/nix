# Waybar — status bar for niri.
# Modules: clock, workspaces, tray, PipeWire audio, network, battery, swaync notifications.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  niriEnabled = (homelabCfg.desktop.niri.enable or false) && pkgs.stdenv.isLinux;
in {
  config = lib.mkIf niriEnabled {
    programs = {
      waybar = {
        enable = true;

        settings = {
          mainBar = {
            position = "top";
            margin-top = 15;

            modules-left = [
              "clock"
              "niri/workspaces"
            ];

            modules-center = [
              "tray"
            ];

            modules-right = [
              "pulseaudio"
              "network"
              "battery"
              "custom/notification"
            ];

            clock = {
              interval = 60;
              format = "{:%H:%M}";
              max-length = 25;
            };

            "niri/workspaces" = {
              format = "{icon}";
              format-icons = {
                active = "";
                default = "";
              };
            };

            tray = {
              icon-size = 21;
              spacing = 10;
            };

            pulseaudio = {
              format = "{volume}% {icon}";
              format-bluetooth = "{volume}% {icon}";
              format-muted = "";
              format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                phone = "";
                phone-muted = "";
                portable = "";
                car = "";
                default = ["" ""];
              };
              scroll-step = 1;
              on-click = "pwvucontrol";
              ignored-sinks = ["Easy Effects Sink"];
            };

            network = {
              format = "{ifname}";
              format-wifi = "{essid} ";
              format-ethernet = "󰊗";
              format-disconnected = ""; # An empty format will hide the module.
              tooltip-format = "{ifname} via {gwaddr} 󰊗";
              tooltip-format-wifi = "{essid} ({signalStrength}%) ";
              tooltip-format-ethernet = "{ifname} ";
              tooltip-format-disconnected = "Disconnected";
              max-length = 50;
            };

            battery = {
              interval = 60;
              states = {
                warning = 30;
                critical = 15;
              };
              format = "{capacity}% {icon}";
              format-icons = ["" "" "" "" ""];
              max-length = 25;
            };

            "custom/notification" = {
              tooltip = true;
              format = "<span size='16pt'>{icon}</span>";
              format-icons = {
                notification = "󱅫";
                none = "󰂜";
                dnd-notification = "󰂠";
                dnd-none = "󰪓";
                inhibited-notification = "󰂛";
                inhibited-none = "󰪑";
                dnd-inhibited-notification = "󰂛";
                dnd-inhibited-none = "󰪑";
              };
              return-type = "json";
              exec-if = "which swaync-client";
              exec = "swaync-client -swb";
              on-click = "swaync-client -t -sw";
              on-click-right = "swaync-client -d -sw";
              escape = true;
            };
          };
        };
      };
    };
  };
}
