# Impermanence — ephemeral root filesystem with explicit persistence.
# Root is rolled back to a blank ZFS snapshot on every boot (see _boot.nix).
# Only paths listed here survive reboots; everything else is wiped.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options.homelab = {
    impermanence = lib.mkEnableOption "Enable Impermanence";
  };

  config = lib.mkIf homelabCfg.impermanence {
    environment.persistence."/nix/persist" = {
      hideMounts = true;

      directories = lib.mkMerge [
        # Non-ZFS machines need explicit persistence for logs and NixOS state
        (lib.mkIf (!homelabCfg.isRootZFS) [
          "/var/log"
          # https://github.com/nix-community/impermanence/issues/178
          "/var/lib/nixos"
        ])
        # Desktop-specific state (login manager, bluetooth pairings, fingerprints, WiFi)
        (lib.mkIf (homelabCfg.role == "desktop") [
          "/var/cache/tuigreet"
          "/var/lib/bluetooth"
          "/var/lib/fprint"
          "/var/lib/NetworkManager"
          "/etc/NetworkManager/system-connections"
        ])
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

    # ZFS datasets need neededForBoot so they mount early enough for impermanence
    fileSystems = lib.mkIf homelabCfg.isRootZFS (lib.mkMerge [
      {
        "/".neededForBoot = true;
        "/nix".neededForBoot = true;
        "/nix/persist".neededForBoot = true;
        "/var/backup".neededForBoot = true;
        "/var/lib/nixos".neededForBoot = true;
        "/var/log".neededForBoot = true;
      }
      (lib.mkIf (homelabCfg.role == "desktop") {
        "/home".neededForBoot = true;
      })
    ]);
  };
}
