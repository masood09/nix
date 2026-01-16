let
  rdisk1 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi0";
  rdisk2 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi1";
in {
  disko.devices = {
    disk = {
      rdisk1 = {
        device = "/dev/disk/by-id/${rdisk1}";
        type = "disk";

        content = {
          type = "gpt";

          partitions = {
            efi = {
              type = "EF00";
              size = "1G";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
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

      rdisk2 = {
        device = "/dev/disk/by-id/${rdisk2}";
        type = "disk";

        content = {
          type = "gpt";

          partitions = {
            efi = {
              type = "EF00";
              size = "1G";

              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot-mirror";
              };
            };

            boot = {
              size = "512M";

              content = {
                type = "zfs";
                pool = "bpool";
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
    };

    zpool = {
      rpool = {
        type = "zpool";
        mode = "mirror";

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
          root = {
            type = "zfs_fs";

            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "prompt";
              mountpoint = "none";
            };
          };

          "root/empty" = {
            type = "zfs_fs";
            mountpoint = "/";
            postCreateHook = "zfs snapshot rpool/root/empty@start";

            options = {
              mountpoint = "legacy";
            };
          };

          "root/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";

            options = {
              mountpoint = "legacy";
            };
          };

          "root/nix/persist" = {
            type = "zfs_fs";
            mountpoint = "/nix/persist";

            options = {
              mountpoint = "legacy";
            };
          };

          "root/var/lib/nixos" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/nixos";

            options = {
              mountpoint = "legacy";
            };
          };

          "root/var/lib/tailscale" = {
            type = "zfs_fs";
            mountpoint = "/var/lib/tailscale";

            options = {
              mountpoint = "legacy";
            };
          };

          "root/var/log" = {
            type = "zfs_fs";
            mountpoint = "/var/log";

            options = {
              mountpoint = "legacy";
            };
          };

          "root/reserved" = {
            type = "zfs_fs";

            options = {
              canmount = "off";
              mountpoint = "none";
              refreservation = "2G";
            };
          };
        };
      };
    };
  };
}
