# arrakis — ThinkPad T14 Gen 3 laptop, NixOS desktop with Niri compositor.
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
        "nvme-Patriot_M.2_P300_512GB_P300WCBA24090657926"
      ];
    };
  };
}
