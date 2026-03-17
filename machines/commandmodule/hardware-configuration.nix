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
        "xhci_pci"
        "ahci"
        "nvme"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
    };

    kernelModules = [
      # WiFi (Intel Wireless - iwlwifi stack)
      "iwlwifi"
      "iwlmvm"

      # Ethernet (Intel e1000e)
      "e1000e"

      # Thinkpad specific
      "thinkpad_acpi"

      # Power management / thermal
      "intel_pmc_core"
      "intel_rapl_msr"
      "intel_cstate"
      "intel_pch_thermal"

      # KVM
      "kvm_intel"
      "kvm"
    ];

    extraModulePackages = [];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware = {
    enableRedistributableFirmware = true;
    firmware = [pkgs.linux-firmware];
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
