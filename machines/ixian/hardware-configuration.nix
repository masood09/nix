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

    # TECH DEBT: linux-zen 7.3.4 panics at boot on this board (NULL pointer
    # dereference in process_one_work via bh_worker, while xhci_hcd probes the
    # USB controller), and unstable has dropped 7.2 as end-of-life. Use the LTS
    # kernel, which still supports the RDNA4 GPU, until a fixed 7.3.x zen
    # release lands, then drop this override to return to the shared htpc
    # zen kernel.
    kernelPackages = lib.mkForce pkgs.linuxPackages;

    kernelModules = [
      "kvm-amd"
      "kvm"
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
