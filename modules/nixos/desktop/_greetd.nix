# Greetd + tuigreet — desktop login manager for Niri sessions.
# Encrypted non-ZFS desktops skip the greeter and start the primary user's
# session directly because the user already authenticated at boot. PAM still
# handles fingerprint auth and GNOME Keyring unlocks for interactive logins.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  # Only non-ZFS desktops use systemd-boot + LUKS in this repo, so they are
  # the only systems where a second greetd password prompt is redundant.
  autoLoginFromBootPassword =
    homelabCfg.desktop.enable
    && homelabCfg.isEncryptedRoot
    && !homelabCfg.isRootZFS;
in {
  config = lib.mkIf homelabCfg.desktop.enable {
    services = {
      greetd = {
        enable = true;

        settings = {
          # Start the primary desktop session immediately after disk unlock on
          # encrypted non-ZFS machines. ZFS desktops keep the greeter.
          initial_session = lib.mkIf autoLoginFromBootPassword {
            command = "niri-session";
            user = homelabCfg.primaryUser.userName;
          };

          # Fallback greeter for ZFS desktops and subsequent logins after the
          # initial auto-login session ends (e.g. user logs out and back in).
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
            user = "greeter";
          };
        };
      };
    };

    # PAM: unlock GNOME Keyring on password login; allow fingerprint if hw present.
    # Neither fingerprint nor auto-login supplies a password, so keyring stays
    # locked in those paths (see docs/desktop.org Pain Points / Future Improvements).
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
