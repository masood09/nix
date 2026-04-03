# Noctalia desktop shell (home-manager side) — enables the HM module,
# declares settings, and manages the plugin registry. The HM module is
# imported in home.nix; this file activates and configures it when
# desktop.shell == "noctalia". Settings are captured from the GUI via
# IPC diff and declared here so Nix remains the source of truth.
# Plugins: the model-usage bar widget (AI coding assistant stats) is
# conditionally enabled when any supported assistant (claude-code, etc.)
# is active.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  shellIsNoctalia = ((homelabCfg.desktop.shell or "none") == "noctalia") && pkgs.stdenv.isLinux;
  claudeCodeEnabled = homelabCfg.programs.claude-code.enable or false;
  codexEnabled = homelabCfg.programs.codex-cli.enable or false;
  # Enable the model-usage plugin when any AI coding assistant is active
  modelUsageEnabled = claudeCodeEnabled || codexEnabled;
in {
  config = lib.mkIf shellIsNoctalia {
    programs = {
      noctalia-shell = {
        enable = true;
        settings = {
          appLauncher = {
            enableClipboardHistory = true;
            terminalCommand = "kitty -e";
          };

          bar = {
            barType = "floating";
            # mkForce: the HM module defaults to 1.0; semi-transparent bar
            # gives floating capsules a subtle backdrop
            backgroundOpacity = lib.mkForce 0.50;
            useSeparateOpacity = true;
            density = "spacious";
            marginVertical = 12;
            marginHorizontal = 12;
            widgets = {
              left = [
                {
                  id = "Workspace";
                  labelMode = "none";
                }
                {
                  id = "ActiveWindow";
                  maxWidth = 500;
                }
                {
                  id = "MediaMini";
                }
              ];
              center = [
                {
                  id = "Tray";
                }
              ];
              right =
                lib.optional modelUsageEnabled {
                  id = "plugin:model-usage";
                }
                ++ [
                  {
                    id = "Battery";
                  }
                  {
                    id = "Volume";
                  }
                  {
                    id = "Brightness";
                  }
                  {
                    id = "Clock";
                  }
                  {
                    id = "NotificationHistory";
                  }
                  {
                    id = "ControlCenter";
                  }
                ];
            };
          };

          # Settings panel opens as a centered overlay instead of attached to the bar
          ui = {
            settingsPanelMode = "centered";
          };

          dock = {
            enabled = false;
          };

          general = {
            animationDisabled = true;
            clockFormat = "ddd, MMM dd HH:mm  ";
            lockScreenAnimations = true;
            passwordChars = true;
          };

          idle = {
            enabled = true;
          };

          # On-screen display (volume/brightness) centred at the bottom
          osd = {
            location = "bottom_center";
          };

          # Power menu: 5s countdown (halved from default 10s), UEFI reboot
          # hidden since it's rarely needed on these machines
          sessionMenu = {
            countdownDuration = 5000;
            powerOptions = [
              {
                action = "lock";
                enabled = true;
                keybind = "1";
              }
              {
                action = "suspend";
                enabled = true;
                keybind = "2";
              }
              {
                action = "hibernate";
                enabled = true;
                keybind = "3";
              }
              {
                action = "reboot";
                enabled = true;
                keybind = "4";
              }
              {
                action = "logout";
                enabled = true;
                keybind = "5";
              }
              {
                action = "shutdown";
                enabled = true;
                keybind = "6";
              }
              {
                action = "rebootToUefi";
                enabled = false;
                keybind = "7";
              }
            ];
          };
        };

        pluginSettings = {
          model-usage = lib.mkIf modelUsageEnabled {
            providers = {
              claude = {
                enabled = claudeCodeEnabled;
                statsPath = "~/.claude/stats-cache.json";
                credentialsPath = "~/.claude/.credentials.json";
              };
              codex = {
                enabled = codexEnabled;
              };
              copilot = {
                enabled = false;
              };
              openrouter = {
                enabled = false;
                apiKey = "";
              };
              zen = {
                enabled = false;
                apiKey = "";
              };
            };
            barDisplayMode = "active";
            barCycleIntervalSec = 5;
            barMetric = "usage";
            refreshIntervalSec = 30;
          };
        };
      };
    };

    # Plugin registry (plugins.json) — separate from settings.json.
    # Noctalia auto-installs enabled plugins from declared sources on startup.
    xdg = {
      configFile = {
        "noctalia/plugins.json" = {
          text = builtins.toJSON {
            version = 2;
            sources = [
              {
                enabled = true;
                name = "Noctalia Plugins";
                url = "https://github.com/noctalia-dev/noctalia-plugins";
              }
            ];
            states = lib.optionalAttrs modelUsageEnabled {
              model-usage = {
                enabled = true;
                sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
              };
            };
          };
        };
      };
    };
  };
}
