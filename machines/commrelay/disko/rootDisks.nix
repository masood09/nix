{
  config,
  lib,
  ...
}: let
  byId = id: "/dev/disk/by-id/${id}";

  rootIds = config.homelab.disks.root;
  rootDevs = map byId rootIds;

  # Non-mirrored: only one EFI mountpoint
  efiMounts = ["/boot"];

  # Helper: one disk = EFI + ZFS partition that feeds rpool
  mkRootDisk = {
    device,
    efiMountpoint,
  }: {
    type = "disk";
    inherit device;
    content = {
      type = "gpt";
      partitions = {
        efi = {
          type = "EF00";
          size = "1G";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = efiMountpoint;
            mountOptions = ["umask=0077"];
          };
        };

        nixos = {
          end = "-1M";
          content = {
            type = "zfs";
            pool = "rpool";
          };
        };
      };
    };
  };

  # Build: { root1 = {...}; }
  rootDiskAttrs = lib.listToAttrs (lib.imap0 (i: dev: {
      name = "root${toString (i + 1)}";
      value = mkRootDisk {
        device = dev;
        efiMountpoint = builtins.elemAt efiMounts i;
      };
    })
    rootDevs);

  # Helper: dataset with legacy mountpoint
  mkLegacy = mountpoint: extra: ({
      type = "zfs_fs";
      inherit mountpoint;
      options = {mountpoint = "legacy";} // (extra.options or {});
    }
    // (builtins.removeAttrs extra ["options"]));
in {
  assertions = [
    {
      assertion = builtins.length rootIds == 1;
      message = "homelab.disks.root must have exactly 1 disk for non-mirrored rpool.";
    }
  ];

  disko.devices = {
    disk = rootDiskAttrs;

    zpool.rpool = {
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
        relatime = "on";
        xattr = "sa";
        "com.sun:auto-snapshot" = "false";
      };

      mountpoint = "/";

      datasets = {
        # Encrypted container dataset (no mountpoint)
        root = {
          type = "zfs_fs";
          options = {
            encryption = "aes-256-gcm";
            keyformat = "passphrase";
            keylocation = "prompt";
            mountpoint = "none";
          };
        };

        "root/empty" = mkLegacy "/" {
          postCreateHook = "zfs snapshot rpool/root/empty@start";
        };

        "root/nix" = mkLegacy "/nix" {};

        "root/nix/persist" = mkLegacy "/nix/persist" {};

        "root/var/backup" = mkLegacy "/var/backup" {};

        "root/var/lib/nixos" = mkLegacy "/var/lib/nixos" {};

        "root/var/log" = mkLegacy "/var/log" {};

        "root/reserved" = {
          type = "zfs_fs";
          options = {
            canmount = "off";
            mountpoint = "none";
            refreservation = "9G";
          };
        };
      };
    };
  };
}
