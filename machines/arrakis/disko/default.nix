# Disko disk layout — single-disk LUKS+ext4 with tmpfs root (laptop).
{...}: {
  imports = [
    ../../../modules/nixos/disko/_root-disk-single-ext4.nix
  ];
}
