# Hardware config — bare-metal Intel N100 mini PC (x86_64), single NVMe,
# Realtek RTL8111 NIC. Encrypted ZFS root with initrd SSH for remote unlock.
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
        "r8169" # Realtek ethernet for initrd networking
      ];

      # Loaded explicitly so the NIC is up before the initrd SSH server starts
      kernelModules = [
        "r8169"
      ];
    };

    # Static IP for initrd SSH (remote ZFS unlock)
    kernelParams = [
      "ip=10.0.20.4::10.0.20.1:255.255.255.0:${config.homelab.networking.hostName}:enp1s0:none"
    ];

    kernelModules = ["kvm-intel"];
    extraModulePackages = [];
  };

  nixpkgs = {
    hostPlatform = lib.mkDefault "x86_64-linux";
  };

  hardware = {
    cpu = {
      intel = {
        updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
      };
    };
  };
}
