{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "igb"
      ];

      kernelModules = [];
    };

    kernelParams = [
      "ip=10.0.1.14::10.0.1.1:255.255.255.0:${config.homelab.networking.hostName}:eno2:"
    ];

    zfs.extraPools = [
      "dpool"
      "fpool"
    ];

    kernelModules = [
      "kvm-intel"
    ];

    extraModulePackages = [];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
