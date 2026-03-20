# Niri compositor — tiling Wayland compositor with Bitwarden polkit policy.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options = {
    homelab = {
      desktop = {
        niri = {
          enable = lib.mkEnableOption "Niri Wayland compositor";
        };
      };
    };
  };

  config = lib.mkIf homelabCfg.desktop.niri.enable {
    programs = {
      niri = {
        enable = true;
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

    environment = {
      # Bitwarden polkit policy for system auth unlock
      systemPackages = [
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
    };
  };
}
