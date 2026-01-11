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
        "ahci"
        "ehci_pci"
        "megaraid_sas"
        "usb_storage"
        "sd_mod"
        "ixgbe"
        "i40e"
      ];

      kernelModules = [];
    };

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
    supportedFilesystems = ["zfs"];
    zfs.extraPools = ["dpool"];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # TODO: Remove the hardcoded value once we are ready to re-install.
  networking.hostId = lib.mkForce "cadd42b4";
}
