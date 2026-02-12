{
  config,
  lib,
  ...
}: {
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_postgresql.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab.disks = {
    root = [
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi0"
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi1"
    ];

    data = [
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi2"
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi3"
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi4"
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi5"
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi6"
      "scsi-0QEMU_QEMU_HARDDISK_drive-scsi7"
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
