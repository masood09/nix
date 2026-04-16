# sonic — ThinkPad T490 laptop, NixOS desktop with Niri compositor.
# Single NVMe root, LUKS-encrypted ext4 (LVM), tmpfs impermanence.
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
      # NOTE: This disk ID is shared with machines/commandmodule/default.nix —
      # both configs target the same physical T490 NVMe. Only one machine is
      # deployed on the hardware at a time; disko only runs on the active
      # config, so the overlap is benign. If sonic ever moves to different
      # hardware, update this to the new disk's by-id name.
      root = [
        "nvme-INTEL_SSDPEKKF256G8L_BTHP94351NSP256B"
      ];
    };
  };
}
