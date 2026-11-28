# Disk declarations — disk-by-id paths for ZFS pools.
# Used by disko and the ZFS module to build pool vdevs.
# Machines populate these in their _config.nix.
{lib, ...}: {
  options = {
    homelab = {
      disks = {
        root = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Disk-by-id list for the root pool";
        };

        fast = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Disk-by-id list for the fast pool";
        };

        data = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [];
          description = "Disk-by-id list for the data pool";
        };

        rootReservation = lib.mkOption {
          type = lib.types.str;
          default = "10G";
          example = "24G";
          description = ''
            refreservation of rpool/root/reserved in the shared ZFS root
            layouts (modules/nixos/disko/_root-disk*.nix): space held back so
            the pool never fills completely. A ZFS size, not a percentage; to
            keep ~20% free, set it from the pool's size. Changing it on an
            installed pool needs a matching `zfs set refreservation=`.
          '';
        };
      };
    };
  };
}
