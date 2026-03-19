# caretaker — core network services (DNS filtering + UPS monitoring).
# Non-ZFS: uses tmpfs root with LUKS-encrypted ext4 /nix for impermanence.
{
  imports = [
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab = {
    disks = {
      root = [
        "nvme-HighRel_512GB_SSD_MP27W06206776"
      ];
    };
  };

  # tmpfs root — wiped on every reboot (impermanence without ZFS)
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
}
