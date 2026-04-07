# Noctalia desktop shell (home-manager side) — enables the HM module,
# declares settings, and manages the plugin registry. The HM module is
# imported in home.nix; this file activates and configures it when
# desktop.shell == "noctalia". Settings are captured from the GUI via
# IPC diff and declared here so Nix remains the source of truth.
# Plugins: the model-usage bar widget (AI coding assistant stats) is
# conditionally enabled when any supported assistant (Claude Code, Codex,
# opencode) is active.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  shellIsNoctalia = ((homelabCfg.desktop.shell or "none") == "noctalia") && pkgs.stdenv.isLinux;
  # Only render the bar widget on machines that actually expose Bluetooth in
  # the machine-level hardware profile; desktops without an adapter should not
  # show a dead control.
  bluetoothEnabled = homelabCfg.hardware.bluetooth.enable or false;
  claudeCodeEnabled = homelabCfg.programs.claude-code.enable or false;
  codexEnabled = homelabCfg.programs.codex-cli.enable or false;
  opencodeEnabled = homelabCfg.programs.opencode.enable or false;
  # Install and configure the model-usage plugin when any supported assistant
  # is active so the bar widget and plugin registry stay in sync.
  modelUsageEnabled = claudeCodeEnabled || codexEnabled || opencodeEnabled;
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
                  colorizeIcons = true;
                  # Vanish when no window is focused; scroll only on hover to
                  # avoid accidental workspace switches
                  hideMode = "hidden";
                  maxWidth = 500;
                  scrollingMode = "hover";
                  showIcon = true;
                  showText = true;
                  textColor = "none";
                  useFixedWidth = false;
                }
                {
                  id = "MediaMini";
                  # Compact now-playing capsule: album art + progress ring,
                  # artist before title, no audio visualiser
                  hideMode = "hidden";
                  hideWhenIdle = false;
                  maxWidth = 500;
                  panelShowAlbumArt = true;
                  scrollingMode = "hover";
                  showAlbumArt = true;
                  showArtistFirst = true;
                  showProgressRing = true;
                  showVisualizer = false;
                  textColor = "none";
                  useFixedWidth = false;
                  visualizerType = "linear";
                }
              ];
              # Mirror the current GUI-customized layout: keep the middle empty,
              # anchor the tray on the right, and only render the Bluetooth
              # control when the machine enables Bluetooth hardware.
              center = [];
              right =
                [
                  {
                    id = "Tray";
                    # Flat tray: no drawer chevron, no icon recolouring.
                    blacklist = [];
                    chevronColor = "none";
                    colorizeIcons = false;
                    drawerEnabled = false;
                    hidePassive = false;
                    pinned = [];
                  }
                ]
                ++ lib.optional modelUsageEnabled {
                  id = "plugin:model-usage";
                }
                ++ lib.optional bluetoothEnabled {
                  id = "Bluetooth";
                  displayMode = "onhover";
                  iconColor = "none";
                  textColor = "none";
                }
                ++ [
                  {
                    id = "Battery";
                    # Icon-only in the bar; auto-hide on desktops without a battery;
                    # expose performance-mode and power-profile toggles in the popup
                    displayMode = "icon-always";
                    hideIfIdle = false;
                    hideIfNotDetected = true;
                    showNoctaliaPerformance = true;
                    showPowerProfiles = true;
                  }
                  {
                    id = "Volume";
                    # Keep the volume readout always visible; middle-click opens
                    # pwvucontrol (PipeWire) with pavucontrol fallback.
                    displayMode = "alwaysShow";
                    middleClickCommand = "pwvucontrol || pavucontrol";
                  }
                  {
                    id = "Brightness";
                    applyToAllMonitors = false;
                    displayMode = "alwaysShow";
                    iconColor = "none";
                    textColor = "none";
                  }
                  {
                    id = "Clock";
                    # Widget-level format (time-first); general.clockFormat is
                    # used for lock screen and other shell surfaces
                    formatHorizontal = "HH:mm ddd, MMM dd";
                    tooltipFormat = "HH:mm ddd, MMM dd";
                  }
                  {
                    id = "NotificationHistory";
                  }
                  {
                    id = "ControlCenter";
                    colorizeDistroLogo = false;
                    colorizeSystemIcon = "none";
                    enableColorization = true;
                    icon = "noctalia";
                    useDistroLogo = true;
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
            # Screen off after 10 min, lock 1 min later, suspend at 30 min
            screenOffTimeout = 600;
            lockTimeout = 660;
            suspendTimeout = 1800;
            fadeDuration = 5;
          };

          noctaliaPerformance = {
            disableWallpaper = false;
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
