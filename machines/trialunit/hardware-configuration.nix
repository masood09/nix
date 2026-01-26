{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ata_piix"
        "uhci_hcd"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];

      kernelModules = [];
    };

    kernelParams = [
      "ip=10.0.20.4::10.0.20.1:255.255.255.0:${config.homelab.networking.hostName}:ens18:"
    ];

    zfs.extraPools = [
      "dpool"
    ];

    kernelModules = [];

    extraModulePackages = [];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
