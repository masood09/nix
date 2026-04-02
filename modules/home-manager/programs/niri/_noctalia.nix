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
  # codexEnabled = homelabCfg.programs.codex.enable or false;
  # Enable the model-usage plugin when any AI coding assistant is active
  modelUsageEnabled = claudeCodeEnabled; # || codexEnabled
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
            # mkForce: the HM module sets a default of 1.0; fully transparent
            # bar lets the floating capsules stand on their own
            backgroundOpacity = lib.mkForce 0.0;
            useSeparateOpacity = true;
            density = "spacious";
            marginVertical = 8;
            marginHorizontal = 6;
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
                enabled = false; # codexEnabled
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
