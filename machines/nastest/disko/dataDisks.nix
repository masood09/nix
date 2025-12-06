let
  ddisk1 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi2";
  ddisk2 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi3";
  ddisk3 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi4";
  ddisk4 = "scsi-0QEMU_QEMU_HARDDISK_drive-scsi5";
in {
  disko.devices = {
    disk = {
      data1 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk1}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };

      data2 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk2}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };

      data3 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk3}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };

      data4 = {
        type = "disk";
        device = "/dev/disk/by-id/${ddisk4}";

        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "dpool";
              };
            };
          };
        };
      };
    };

    zpool = {
      dpool = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";

            vdev = [
              {
                mode = "raidz1";

                members = [
                  "data1"
                  "data2"
                  "data3"
                  "data4"
                ];
              }
            ];
          };
        };

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

        datasets = {
          DataStore = {
            type = "zfs_fs";

            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///nix/secret/DataStore.key";
              canmount = "on";
              mountpoint = "/mnt/DataStore";
              "com.sun:auto-snapshot" = "true";
            };
          };
        };
      };
    };
  };
}
