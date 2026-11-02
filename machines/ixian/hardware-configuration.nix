# Hardware config — ASRock B550 PG Riptide, AMD Ryzen 5 5600, Radeon RX 9060 XT.
{
  config,
  lib,
  modulesPath,
  pkgs,
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
        "ahci"
        "usb_storage"
        "sd_mod"
        "r8169"
      ];

      kernelModules = [
        "r8169"
      ];
    };

    kernelModules = [
      "kvm-amd"
      "kvm"
    ];

    # DHCP is used by the initrd SSH server for remote LUKS unlocking.
    kernelParams = [
      "ip=dhcp"
    ];

    extraModulePackages = [];
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  hardware = {
    enableRedistributableFirmware = true;
    firmware = [pkgs.linux-firmware];

    cpu = {
      amd = {
        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
    };
  };
}
