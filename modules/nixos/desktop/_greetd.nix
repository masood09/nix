# Greetd — tuigreet TUI login manager.
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
            command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
            user = "greeter";
          };
        };
      };
    };

    security = {
      pam = {
        services = {
          greetd = {
            # Enable fingerprint authentication at login
            fprintAuth = config.homelab.hardware.fingerprint.enable;
          };
        };
      };
    };
  };
}
