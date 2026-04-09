# commandmodule — ThinkPad laptop, NixOS desktop with Niri compositor.
# Single NVMe root, encrypted ZFS, impermanence.
{inputs, ...}: {
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_config.nix
    ./_networking.nix
    ./_niri.nix
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
        "nvme-INTEL_SSDPEKKF256G8L_BTHP94351NSP256B"
      ];
    };
  };
}
