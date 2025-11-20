{
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = ["ata_piix" "uhci_hcd" "virtio_pci" "virtio_scsi" "sd_mod" "sr_mod"];
      kernelModules = [];
    };

    supportedFilesystems = ["zfs"];
    kernelModules = [];
    extraModulePackages = [];

    loader = {
      efi = {
        canTouchEfiVariables = false;
        efiSysMountPoint = "/boot/efis/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part2";
      };

      generationsDir.copyKernels = true;

      grub = {
        enable = true;

        mirroredBoots = [
          {
            devices = ["nodev"];
            path = "/boot/efis/scsi-0QEMU_QEMU_HARDDISK_drive-scsi0-part2";
          }
          {
            devices = ["nodev"];
            path = "/boot/efis/scsi-0QEMU_QEMU_HARDDISK_drive-scsi1-part2";
          }
        ];

        efiInstallAsRemovable = true;
        copyKernels = true;
        efiSupport = true;
        zfsSupport = true;
      };
    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s6.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
