# Noctalia desktop shell (home-manager side) — enables the HM module
# and declares settings. The HM module is imported in home.nix; this
# file activates and configures it when desktop.shell == "noctalia".
# Settings are captured from the GUI via IPC diff and declared here
# so Nix remains the source of truth (~/.config/noctalia/settings.json
# becomes a read-only symlink).
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  shellIsNoctalia = ((homelabCfg.desktop.shell or "none") == "noctalia") && pkgs.stdenv.isLinux;
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
              right = [
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
      };
    };
  };
}
