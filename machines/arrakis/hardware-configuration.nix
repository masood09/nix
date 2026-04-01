# Hardware config — ThinkPad T14 Gen 3 AMD laptop (bare-metal AMD x86_64).
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
      # systemd-based initrd for LUKS unlock via systemd-cryptsetup.
      # Required for Plymouth integration (future) — the scripted initrd's
      # cryptsetup-askpass does not integrate with Plymouth's password agent.
      systemd = {
        enable = true;
      };

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usb_storage"
        "sd_mod"
      ];
    };

    kernelModules = [
      # WiFi (Intel AX WiFi - iwlwifi stack)
      "iwlwifi"
      "iwlmvm"

      # Ethernet (Realtek r8169)
      "r8169"

      # ThinkPad specific
      "thinkpad_acpi"

      # AMD thermal
      "k10temp"

      # KVM
      "kvm_amd"
      "kvm"
    ];

    kernelParams = [
      # Use modern AMD P-State driver with energy performance preference
      "amd_pstate=active"
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
