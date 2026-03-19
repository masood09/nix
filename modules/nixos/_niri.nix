# Niri compositor — system-level setup: greetd login, keyring unlock,
# Bitwarden polkit, font discovery, and Wayland session variables.
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

    # Bitwarden polkit policy for system auth unlock
    environment.systemPackages = [
      (pkgs.writeTextDir "share/polkit-1/actions/com.bitwarden.Bitwarden.policy" ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE policyconfig PUBLIC
         "-//freedesktop//DTD PolicyKit Policy Configuration 1.0//EN"
         "http://www.freedesktop.org/standards/PolicyKit/1.0/policyconfig.dtd">
        <policyconfig>
          <action id="com.bitwarden.Bitwarden.unlock">
            <description>Unlock Bitwarden</description>
            <message>Authenticate to unlock Bitwarden</message>
            <defaults>
              <allow_any>auth_self</allow_any>
              <allow_inactive>auth_self</allow_inactive>
              <allow_active>auth_self</allow_active>
            </defaults>
          </action>
        </policyconfig>
      '')
    ];

    # Font discovery
    fonts.fontconfig.enable = true;

    # Wayland environment hints
    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
    };
  };
}
