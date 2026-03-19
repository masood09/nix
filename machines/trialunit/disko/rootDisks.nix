# Root pool — uses shared mirrored ZFS layout from modules/nixos/disko.
{...}: {
  imports = [
    ../../../modules/nixos/disko/_root-disks.nix
  ];
}
