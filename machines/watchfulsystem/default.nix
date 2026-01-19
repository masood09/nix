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
      "scsi-360426a0eab5646b58549a8cc41c1c1aa"
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
