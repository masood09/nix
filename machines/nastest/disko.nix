let
  disk1 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
  disk2 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
  persistMountPath = "/nix/persist";
in {
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/disk/by-id/${disk1}";

        content = {
          type = "gpt";

          partitions = {
            efi = {
              size = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efis/${disk1}-part2";
              };
            };

            bpool = {
              size = "1G";
              content = {
                type = "zfs";
                pool = "bpool";
              };
            };

            rpool = {
              end = "-1M";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };

            bios = {
              size = "100%";
              type = "EF02";
            };
          };
        };
      };

      mirror = {
        type = "disk";
        device = "/dev/disk/by-id/${disk2}";

        content = {
          type = "gpt";

          partitions = {
            efi = {
              size = "256M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot/efis/${disk2}-part2";
              };
            };

            bpool = {
              size = "1G";
              content = {
                type = "zfs";
                pool = "bpool";
              };
            };

            rpool = {
              end = "-1M";
              content = {
                type = "zfs";
                pool = "rpool";
              };
            };

            bios = {
              size = "100%";
              type = "EF02";
            };
          };
        };
      };
    };

    zpool = {
      bpool = {
        type = "zpool";
        mode = "mirror";

        options = {
          ashift = "12";
          autotrim = "on";
          compatibility = "grub2";
        };

        rootFsOptions = {
          acltype = "posixacl";
          canmount = "off";
          compression = "lz4";
          devices = "off";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };

        mountpoint = "/boot";
        datasets = {
          nixos = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "nixos/root" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/boot";
          };
        };
      };

      rpool = {
        type = "zpool";
        mode = "mirror";

        options = {
          ashift = "12";
          autotrim = "on";
        };

        rootFsOptions = {
          acltype = "posixacl";
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
          nixos = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "nixos/var" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "nixos/empty" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/nixos/empty@start";
          };

          "nixos/var/log" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/log";
          };

          "nixos/var/lib/nixos" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/var/lib/nixos";
          };

          "nixos/nix" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = "/nix";
          };

          "nixos/persist" = {
            type = "zfs_fs";
            options.mountpoint = "legacy";
            mountpoint = persistMountPath;
          };
        };
      };
    };
  };
}
