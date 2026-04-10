# Greetd + tuigreet — desktop login manager for Niri sessions.
#
# Two login flows live in this file:
#
#   1. Interactive (default_session): tuigreet collects a password (or
#      fingerprint, if hardware supports it) and PAM handles GNOME Keyring
#      unlock through enableGnomeKeyring on the greetd PAM service. Fingerprint
#      auth still cannot unlock the keyring because pam_fprintd short-circuits
#      the auth stack before pam_gnome_keyring sees a password (see Pain Points
#      in docs/desktop.org).
#
#   2. Auto-login from boot password (initial_session): on encrypted non-ZFS
#      desktops greetd starts the primary user's session directly after disk
#      unlock, with no password traversing PAM. To still get GNOME Keyring
#      unlocked on that path we attach pam_fde_boot_pw to the session phase: it
#      reads the LUKS passphrase that systemd-cryptsetup cached in the kernel
#      keyring during the systemd initrd and injects it for pam_gnome_keyring
#      to consume. Requires the user's login password to equal the LUKS
#      passphrase; if they diverge the session still starts but the keyring
#      stays locked.
#
# TECH DEBT: pam_fde_boot_pw is pulled from nixpkgs-unstable because the
# package has not landed in nixos-25.11. Drop the inputs.nixpkgs-unstable
# reference once pkgs.pam_fde_boot_pw is available on the pinned channel.
{
  config,
  inputs,
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

  inherit (inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}) pam_fde_boot_pw;
in {
  config = lib.mkIf homelabCfg.desktop.enable (lib.mkMerge [
    {
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

      # PAM: unlock GNOME Keyring on interactive password login; allow
      # fingerprint where hardware supports it. enableGnomeKeyring is also
      # load-bearing for the auto-login mkMerge block below — it provisions
      # the gnome_keyring session rule whose `order` we anchor against, and
      # it owns the actual GKR session start that consumes the injected
      # password. Do not flip it off without rethinking that block.
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
    }

    # Auto-login PAM augmentation — only built into the closure on machines
    # where initial_session actually runs (see file header). Kept in its own
    # mkMerge entry so ZFS desktops never reference pam_fde_boot_pw and never
    # pull the unstable package into their store.
    (lib.mkIf autoLoginFromBootPassword {
      security = {
        pam = {
          services = {
            greetd = {
              rules = {
                session = {
                  fde_boot_pw = {
                    # `optional` so a missing kernel-keyring entry never blocks
                    # the session — we still want the user to land in niri even
                    # if injection silently fails.
                    control = "optional";
                    modulePath = "${pam_fde_boot_pw}/lib/security/pam_fde_boot_pw.so";
                    args = ["inject_for=gkr"];
                    # Run just before pam_gnome_keyring's session entry so the
                    # injected token is already in place when GKR starts. Using
                    # a relative offset (rather than a hardcoded numeric order
                    # like the upstream discourse recipe) survives nixpkgs
                    # renumbering its built-in rules. NB: this read implicitly
                    # depends on enableGnomeKeyring = true above.
                    order = config.security.pam.services.greetd.rules.session.gnome_keyring.order - 10;
                  };
                };
              };
            };
          };
        };
      };
    })
  ]);
}
