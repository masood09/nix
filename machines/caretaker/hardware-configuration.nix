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

    kernel.sysctl = {
      "net.ipv6.conf.all.disable_ipv6" = 1;
      "net.ipv6.conf.default.disable_ipv6" = 1;
      "net.ipv6.conf.lo.disable_ipv6" = 1;
    };

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  fileSystems = {
    "/" = {
      device = "none";
      fsType = "tmpfs";
      options = ["defaults" "size=20G" "mode=0755"];
    };
    "/boot" = {
      device = "/dev/nvme0n1p1";
      fsType = "vfat";
      options = ["umask=0077"];
      neededForBoot = true;
    };
    "/nix" = {
      device = "/dev/mapper/cryptroot";
      fsType = "ext4";
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
