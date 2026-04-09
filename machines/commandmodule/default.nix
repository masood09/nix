# commandmodule — ThinkPad laptop, NixOS desktop with Niri compositor.
# Single NVMe root, encrypted ZFS, impermanence.
{
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_niri.nix
    ./_secrets.nix

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  homelab = {
    disks = {
      root = [
        "nvme-INTEL_SSDPEKKF256G8L_BTHP94351NSP256B"
      ];
    };
  };
}
