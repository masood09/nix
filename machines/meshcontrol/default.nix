{
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab.disks = {
    root = [
      "scsi-360be897f1a3847ccb8118a239ec26e56"
    ];
  };

  fileSystems = {
    "/".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/nix/persist".neededForBoot = true;
    "/var/backup".neededForBoot = true;
    "/var/lib/nixos".neededForBoot = true;
    "/var/log".neededForBoot = true;
  };
}
