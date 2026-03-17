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
      # Hide these mounts from the sidebar of file managers
      hideMounts = true;

      directories = lib.mkMerge [
        (lib.mkIf (!homelabCfg.isRootZFS) [
          "/var/log"
          # inspo: https://github.com/nix-community/impermanence/issues/178
          "/var/lib/nixos"
        ])
        (lib.mkIf (homelabCfg.role == "desktop") [
          "/var/lib/bluetooth"
          "/var/lib/NetworkManager"
          "/etc/NetworkManager/system-connections"
        ])
      ];

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
