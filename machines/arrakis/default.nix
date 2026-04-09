# arrakis — ThinkPad T14 Gen 3 laptop, NixOS desktop with Niri compositor.
# Single NVMe root, LUKS-encrypted ext4 with tmpfs impermanence.
{inputs, ...}: {
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_secrets.nix

    # Desktop-only flake modules kept out of mkNixOSConfig to avoid pulling
    # heavyweight packages (niri, quickshell) into server closures.
    inputs.niri.nixosModules.niri

    ./../../modules/nixos
    ./../../modules/home-manager
  ];

  home-manager = {
    sharedModules = [
      inputs.noctalia.homeModules.default
    ];
  };

  homelab = {
    disks = {
      root = [
        "nvme-Patriot_M.2_P300_512GB_P300WCBA24090657926"
      ];
    };
  };
}
