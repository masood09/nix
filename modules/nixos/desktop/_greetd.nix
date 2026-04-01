# Greetd + tuigreet — TUI login manager that launches niri-session.
# PAM is configured to auto-unlock GNOME Keyring on password login and
# to enable fingerprint auth when the hardware supports it.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  config = lib.mkIf homelabCfg.desktop.enable {
    services = {
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

    # PAM: unlock GNOME Keyring on password login; allow fingerprint if hw present
    security = {
      pam = {
        services = {
          greetd = {
            fprintAuth = config.homelab.hardware.fingerprint.enable;
            enableGnomeKeyring = true;
          };
        };
      };
    };
  };
}
