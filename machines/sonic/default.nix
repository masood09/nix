# sonic — ThinkPad T14 Gen 3 laptop, NixOS desktop with Niri compositor.
# Single NVMe root, encrypted ZFS, impermanence.
{
  imports = [
    ./disko
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
        "nvme-WDC_PC_SN730_SDBQNTY-256G-1001_194364802297"
      ];
    };
  };
}
