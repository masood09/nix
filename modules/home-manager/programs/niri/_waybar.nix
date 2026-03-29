# Waybar — status bar for niri.
# Modules: clock, workspaces, window title, tray, PipeWire audio, network, battery, swaync notifications.
# Stylix provides base16 color variables and fonts (addCss = false in _stylix.nix
# disables its layout CSS). Custom styles use lib.mkAfter to append after Stylix.
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
        systemd = {
          enable = true;
        };

        # Custom CSS appended after Stylix's base16 color definitions
        style = lib.mkAfter ''
          * {
            border: none;
            border-radius: 0px;
            font-family: "Adwaita Sans", "JetBrainsMono Nerd Font Propo", sans-serif;
            font-weight: bold;
            min-height: 0;
            padding: 0;
            margin: 0;
          }

          window#waybar {
            background: transparent;
          }

          tooltip {
            background: transparent;
          }

          tooltip label {
            background: @base00;
            border: 1px solid @base03;
            border-radius: 12px;
            color: @base05;
            padding: 12px;
          }

          #workspaces {
            background-color: @base00;
            padding: 5px 3px;
            margin: 0 0 0 12px;
            border-radius: 18px;
            border: 1px solid @base01;
            color: @base05;
          }

          #workspaces button {
            padding: 0 6px;
            margin: 0 3px;
            border-radius: 50px;
            color: transparent;
            background-color: @base01;
            transition: all 0.3s ease-in-out;
          }

          #workspaces button.active {
            background-color: @base08;
            color: @base00;
            min-width: 50px;
            transition: all 0.3s ease-in-out;
            font-size: 13px;
          }

          #workspaces button.active:hover {
            background-color: @base08;
          }

          #workspaces button:hover {
            background-color: @base09;
            color: @base00;
            border-radius: 16px;
            min-width: 50px;
            background-size: 400% 400%;
          }

          #workspaces button.urgent {
            background-color: @base08;
            color: @base00;
            border-radius: 16px;
            min-width: 50px;
            background-size: 400% 400%;
            transition: all 0.3s ease-in-out;
          }

          #clock {
            background-color: @base00;
            padding: 0 15px;
            margin: 0 0 0 12px;
            border-radius: 50px;
            border: 1px solid @base01;
            color: @base0A;
          }

          #window {
            background-color: @base00;
            padding: 0 15px;
            margin: 0 0 0 12px;
            border-radius: 50px;
            border: 1px solid @base01;
            color: @base0A;
          }

          .modules-right {
            background-color: @base00;
            margin: 0 12px 0 0;
            border-radius: 50px;
            border: 1px solid @base01;
            color: @base0A;
          }

          #battery,
          #pulseaudio,
          #network,
          #custom-notification {
            padding: 0 10px;
          }
        '';

        settings = {
          mainBar = {
            position = "top";
            margin-top = 12;

            modules-left = [
              "clock"
              "niri/workspaces"
              "niri/window"
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

            "niri/window" = {
              format = "{}";
              seperate-outputs = true;
            };

            tray = {
              icon-size = 21;
              spacing = 10;
            };

            pulseaudio = {
              format = "{volume}% {icon}";
              format-bluetooth = "{volume}% {icon}";
              format-muted = "";
              format-icons = {
                headphone = "";
                hands-free = "";
                headset = "";
                phone = "";
                phone-muted = "";
                portable = "";
                car = "";
                default = ["" ""];
              };
              scroll-step = 1;
              on-click = "pwvucontrol";
              ignored-sinks = ["Easy Effects Sink"];
            };

            network = {
              format = "{ifname}";
              format-wifi = "";
              format-ethernet = "󰊗";
              format-disconnected = ""; # An empty format will hide the module.
              tooltip-format = "{ifname} via {gwaddr} 󰊗";
              tooltip-format-wifi = "{essid} ({signalStrength}%) ";
              tooltip-format-ethernet = "{ifname} ";
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
              format-charging = "{capacity}% 󰂅";
              format-icons = ["󰂎" "󰁻" "󰁾" "󰂀" "󰁹"];
              max-length = 25;
            };

            "custom/notification" = {
              tooltip = true;
              format = "{icon}";
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
