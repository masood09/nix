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
      "scsi-3607e89acda9142e4b05da8dc1205d078"
    ];
  };

  fileSystems = {
    "/var/lib/postgresql".neededForBoot = true;
  };
}
