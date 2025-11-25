{
  disko.devices = {
    zpool = {
      dpool = {
        type = "zpool";

        mode = {
          topology = {
            type = "topology";

            vdev = [
              {
                mode = "raidz2";

                members = [
                  "data1"
                  "data2"
                  "data3"
                  "data4"
                  "data5"
                  "data6"
                  "data7"
                  "data8"
                  "data9"
                  "data10"
                  "data11"
                  "data12"
                ];
              }
            ];
          };
        };

        rootFsOptions = {
          acltype = "posixacl";
          atime = "off";
          canmount = "off";
          compression = "lz4";
          dnodesize = "auto";
          normalization = "formD";
          relatime = "on";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };

        datasets = {
          DataStore = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore";

            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///nix/secret/DataStore.key";
              canmount = "on";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Apps";

            options = {
              canmount = "on";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps/Immich" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Apps/Immich";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps/mailcow" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Apps/mailcow";

            options = {
              canmount = "on";
              recordsize = "16K";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps/MinIO" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Apps/MinIO";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Users" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Users";

            options = {
              canmount = "on";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Users/Masood" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Users/Masood";

            options = {
              canmount = "on";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Users/Tanvir" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Users/Tanvir";

            options = {
              canmount = "on";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Media" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/Media";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/NonBackedUp" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/NonBackedUp";

            options = {
              canmount = "on";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/NonBackedUp/PVE-Data" = {
            type = "zfs_fs";
            mountpoint = "/mnt/DataStore/NonBackedUp/PVE-Data";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "legacy";
              "com.sun:auto-snapshot" = "true";
            };
          };
        };
      };
    };
  };
}
