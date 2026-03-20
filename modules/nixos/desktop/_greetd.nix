# Greetd — TUI-based login manager with tuigreet, GNOME Keyring unlock on login.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  config = lib.mkIf homelabCfg.desktop.niri.enable {
    services = {
      # TUI-based login manager
      greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
            user = "greeter";
          };
        };
      };
    };

    systemd = {
      services = {
        greetd = {
          # Prevent greetd logs from clobbering the TUI
          serviceConfig = {
            Type = "idle";
            StandardInput = "tty";
            StandardOutput = "tty";
            StandardError = "journal";
            TTYReset = true;
            TTYVHangup = true;
            TTYVTDisallocate = true;
          };
        };
      };
    };

    security = {
      pam = {
        services = {
          greetd = {
            # Auto-unlock GNOME Keyring on login via PAM
            enableGnomeKeyring = true;
          };
        };
      };
    };
  };
}
