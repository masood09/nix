# Disko disk layout — single-disk LUKS+LVM (swap + ext4 /nix), tmpfs root (laptop).
{...}: {
  imports = [
    ../../../modules/nixos/disko/_root-disk-single-ext4.nix
  ];
}
