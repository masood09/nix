# Hardware config — Lenovo ThinkCentre M920 (Intel i5-8500, 64 GB), onboard
# Intel I219 (e1000e) and a dual-port Broadcom 10 GbE card (bnx2x). Both NICs
# are in the initrd so either can carry the remote LUKS unlock (_networking.nix);
# bnx2x loads firmware, hence enableRedistributableFirmware.
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
        "usb_storage"
        "sd_mod"
        "e1000e"
        "bnx2x"
      ];

      # Loaded explicitly so the NICs are up before the initrd SSH server starts.
      kernelModules = [
        "e1000e"
        "bnx2x"
      ];
    };

    zfs = {
      # Data pools imported at boot, keyed from /run/secrets (disko/default.nix).
      extraPools = [
        "cipool"
        "agentpool"
      ];
    };

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  hardware = {
    # bnx2x firmware, and Intel microcode: the BIOS (M1UKT56A, 2020) stays as
    # is, so CPU fixes come from the microcode NixOS loads at boot.
    enableRedistributableFirmware = true;

    cpu = {
      intel = {
        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
    };
  };
}
