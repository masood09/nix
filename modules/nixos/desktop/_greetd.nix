# Greetd — sysc-greet graphical login manager.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  config = lib.mkIf homelabCfg.desktop.enable {
    services = {
      sysc-greet = {
        enable = true;
        compositor = "niri";
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
