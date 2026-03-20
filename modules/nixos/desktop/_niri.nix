# Niri compositor — Wayland session with desktop services,
# Bitwarden polkit, font discovery, and session variables.
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

    services = {
      # Desktop service dependencies
      accounts-daemon = {
        enable = true;
      };

      power-profiles-daemon = {
        enable = true;
      };

      printing = {
        enable = true;
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

      # Wayland environment hints
      sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };
    };

    fonts = {
      fontconfig = {
        # Required for user-installed fonts to be discovered
        enable = true;
      };
    };
  };
}
