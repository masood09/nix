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
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
        "r8169"
      ];

      kernelModules = [
        "nvme"
        "r8169"
      ];

      luks.devices."cryptroot" = {
        device = "/dev/nvme0n1p2";
        preLVM = true;
      };
    };

    kernelParams = [
      "ip=10.0.20.2::10.0.20.1:255.255.255.0:${config.homelab.networking.hostName}:enp1s0:"
    ];

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
