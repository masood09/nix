# Greetd — login manager (tuigreet or sysc-greet).
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  inherit (homelabCfg.desktop) greeter;
in {
  options = {
    homelab = {
      desktop = {
        greeter = lib.mkOption {
          default = "tuigreet";
          type = lib.types.enum [
            "tuigreet"
            "sysc-greet"
          ];
          description = "Which greeter to use with greetd.";
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.desktop.enable (lib.mkMerge [
    # sysc-greet — graphical greeter
    (lib.mkIf (greeter == "sysc-greet") {
      services = {
        sysc-greet = {
          enable = true;
          compositor = "niri";
        };
      };

      # Disable fingerprint PAM for greetd — sysc-greet only handles a single
      # password prompt; fprintd's concurrent PAM conversation triggers
      # "Connection refused" on the greetd IPC socket, failing all auth.
      security = {
        pam = {
          services = {
            greetd = {
              fprintAuth = false;
              enableGnomeKeyring = true;
            };
          };
        };
      };
    })

    # tuigreet — TUI greeter (default)
    (lib.mkIf (greeter == "tuigreet") {
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
    })
  ]);
}
