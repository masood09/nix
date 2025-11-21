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

      preLVMCommands = ''
        echo "Waiting for NVMe devices..."
        udevadm settle
        sleep 5
      '';

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

  systemd.network = {
    enable = true;

    networks = {
      "10-enp1s0" = {
        matchConfig.MACAddress = "84:47:09:46:ed:7d";
        networkConfig.DHCP = "yes";

        dhcpV4Config = {
          UseRoutes = true;
          UseDNS = true;
        };
      };
      "20-enp2s0" = {
        matchConfig.MACAddress = "84:47:09:46:ed:7f";
        networkConfig.DHCP = "yes";

        dhcpV4Config = {
          UseRoutes = false;
          UseDNS = false;
        };
      };
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
