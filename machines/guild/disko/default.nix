# Disko layout — shared single-disk encrypted ZFS root (rpool, as on mentat)
# plus two single-disk data pools:
#
#   cipool     Crucial P3 1 TB NVMe (homelab.disks.fast)   CI builds, binary cache
#   agentpool  Patriot P220 1 TB SATA (homelab.disks.data) Hermes agent
#
# Each pool has one encrypted container dataset keyed by a file (no passphrase).
# The keys are sops secrets (_secrets.nix), so they are backed up in the repo
# and appear under /run/secrets before the pools are imported at boot
# (boot.zfs.extraPools, hardware-configuration.nix). Heartbeat's dpool/fpool
# pattern. Service datasets are added later under the containers with
# homelab.zfs.datasets.
{
  config,
  lib,
  ...
}: let
  byId = id: "/dev/disk/by-id/${id}";

  inherit (config.homelab) disks;

  # reserved: ~20% of the disk held back so the pool never fills past ~80%,
  # where ZFS allocation slows down and fragments. Both disks are 1 TB
  # (~931 GiB), so 186G; refreservation takes a size, not a percentage, so
  # change it with the disk.
  pools = {
    cipool = {
      disk = builtins.elemAt disks.fast 0;
      container = "ci";
      reserved = "186G";
    };
    agentpool = {
      disk = builtins.elemAt disks.data 0;
      container = "agent";
      reserved = "186G";
    };
  };

  mkDisk = pool: {disk, ...}: {
    type = "disk";
    device = byId disk;
    content = {
      type = "gpt";
      partitions = {
        ${pool} = {
          end = "-1M";
          content = {
            type = "zfs";
            inherit pool;
          };
        };
      };
    };
  };

  mkPool = pool: {
    container,
    reserved,
    ...
  }: {
    type = "zpool";

    options = {
      ashift = "12";
      autotrim = "on";
    };

    rootFsOptions = {
      acltype = "posixacl";
      atime = "off";
      canmount = "off";
      compression = "zstd";
      dnodesize = "auto";
      normalization = "formD";
      xattr = "sa";
      "com.sun:auto-snapshot" = "false";
    };

    datasets = {
      # Encrypted container (no mountpoint); everything goes underneath it.
      ${container} = {
        type = "zfs_fs";
        options = {
          canmount = "off";
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          keylocation = "file:///run/secrets/${pool}_key";
          mountpoint = "none";
        };
      };

      # Keeps ~20% of the pool free (see pools above).
      reserved = {
        type = "zfs_fs";
        options = {
          canmount = "off";
          mountpoint = "none";
          refreservation = reserved;
        };
      };
    };
  };
in {
  imports = [
    ../../../modules/nixos/disko/_root-disk-single.nix
  ];

  config = {
    assertions = [
      {
        assertion = builtins.length disks.fast == 1;
        message = "guild needs exactly 1 disk in homelab.disks.fast (cipool).";
      }
      {
        assertion = builtins.length disks.data == 1;
        message = "guild needs exactly 1 disk in homelab.disks.data (agentpool).";
      }
    ];

    disko = {
      devices = {
        disk = lib.mapAttrs mkDisk pools;
        zpool = lib.mapAttrs mkPool pools;
      };
    };
  };
}
