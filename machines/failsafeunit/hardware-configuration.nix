{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd = {
      availableKernelModules = [
        "ahci"
        "ehci_pci"
        "megaraid_sas"
        "usb_storage"
        "sd_mod"
        "ixgbe"
      ];

      kernelModules = [ ];
    };
    
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    kernel.sysctl = {
      "net.ipv6.conf.all.disable_ipv6" = 1;
      "net.ipv6.conf.default.disable_ipv6" = 1;
      "net.ipv6.conf.lo.disable_ipv6" = 1;
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  networking.hostId = "cadd42b4";
}
