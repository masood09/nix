# Impermanence — ephemeral root filesystem with explicit persistence.
# ZFS machines: root rolled back to blank snapshot on every boot (see _boot.nix).
# Non-ZFS machines: tmpfs root wiped on every reboot.
# Only paths listed here survive reboots; everything else is wiped.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options = {
    homelab = {
      impermanence = lib.mkEnableOption "Enable Impermanence";
    };
  };

  config = lib.mkIf homelabCfg.impermanence {
    environment = {
      persistence = {
        "/nix/persist" = {
          hideMounts = true;

          directories = lib.mkMerge [
            # Non-ZFS machines need explicit persistence for logs and NixOS state
            (lib.mkIf (!homelabCfg.isRootZFS) [
              "/var/log"
              # https://github.com/nix-community/impermanence/issues/178
              "/var/lib/nixos"
            ])
            # Non-ZFS desktops: persist user home with explicit ownership so
            # impermanence creates the directory in /nix/persist automatically.
            # Bare "/home" won't create subdirectories, leaving the user homeless
            # after a fresh install. ZFS desktops get /home as a dataset instead.
            (lib.mkIf (!homelabCfg.isRootZFS && homelabCfg.role == "desktop") [
              {
                directory = "/home/${homelabCfg.primaryUser.userName}";
                user = homelabCfg.primaryUser.userName;
                group = "users";
                mode = "0700";
              }
            ])
            # Desktop-specific state (login manager, bluetooth pairings, fingerprints, WiFi)
            (lib.mkIf (homelabCfg.role == "desktop") (
              [
                "/var/lib/bluetooth"
                "/var/lib/fprint"
                "/var/lib/NetworkManager"
                "/etc/NetworkManager/system-connections"
              ]
              ++ ["/var/cache/tuigreet"]
            ))
          ];

          # Machine identity and SSH host keys must persist across reboots
          files = [
            "/etc/machine-id"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
          ];
        };
      };
    };

    # Filesystems must mount early enough for impermanence bind-mounts
    fileSystems = lib.mkMerge [
      # ZFS datasets need neededForBoot
      (lib.mkIf homelabCfg.isRootZFS (lib.mkMerge [
        {
          "/" = {
            neededForBoot = true;
          };
          "/nix" = {
            neededForBoot = true;
          };
          "/nix/persist" = {
            neededForBoot = true;
          };
          "/var/backup" = {
            neededForBoot = true;
          };
          "/var/lib/nixos" = {
            neededForBoot = true;
          };
          "/var/log" = {
            neededForBoot = true;
          };
        }
        (lib.mkIf (homelabCfg.role == "desktop") {
          "/home" = {
            neededForBoot = true;
          };
        })
      ]))
      # Non-ZFS: /nix (ext4) must mount early so /nix/persist is available
      (lib.mkIf (!homelabCfg.isRootZFS) {
        "/nix" = {
          neededForBoot = true;
        };
      })
    ];
  };
}
