{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options.homelab.desktop = {
    niri.enable = lib.mkEnableOption "Niri Wayland compositor";
  };

  config = lib.mkIf homelabCfg.desktop.niri.enable {
    programs = {
      niri = {
        enable = true;
      };
    };

    # Login manager
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
          user = "greeter";
        };
      };
    };

    # Prevent greetd logs from clobbering the TUI
    systemd.services.greetd.serviceConfig = {
      Type = "idle";
      StandardInput = "tty";
      StandardOutput = "tty";
      StandardError = "journal";
      TTYReset = true;
      TTYVHangup = true;
      TTYVTDisallocate = true;
    };

    # Auto-unlock GNOME Keyring on login via PAM
    security.pam.services.greetd.enableGnomeKeyring = true;

    # DMS shell dependencies
    services = {
      accounts-daemon.enable = true;
      power-profiles-daemon.enable = true;
      printing.enable = true;
    };

    # Font discovery
    fonts.fontconfig.enable = true;

    # Wayland environment hints
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
