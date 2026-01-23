{
  imports = [
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab.disks = {
    root = [
      "nvme-HighRel_512GB_SSD_MP27W06206776"
    ];
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

  services.tailscale = {
    useRoutingFeatures = "both";

    extraUpFlags = [
      "--advertise-exit-node"
      "--advertise-routes=10.0.0.0/16"
    ];
  };
}
