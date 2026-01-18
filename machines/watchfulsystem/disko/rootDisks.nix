let
  rdisk = "scsi-36054d5864a1b4752bdf492b4a0d7bc4e";
in {
  disko.devices = {
    disk = {
      rdisk = {
        device = "/dev/disk/by-id/${rdisk}";
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
    };

    zpool = {
      rpool = {
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

          "root/var/backup" = {
            type = "zfs_fs";
            mountpoint = "/var/backup";

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
              refreservation = "5G";
            };
          };
        };
      };
    };
  };
}
