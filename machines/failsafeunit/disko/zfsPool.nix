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

            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file:///nix/secret/DataStore.key";
              canmount = "on";
              mountpoint = "/mnt/DataStore";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              mountpoint = "/mnt/DataStore/Apps";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps/Immich" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "/mnt/DataStore/Apps/Immich";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps/mailcow" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              recordsize = "16K";
              mountpoint = "/mnt/DataStore/Apps/mailcow";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Apps/MinIO" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "/mnt/DataStore/Apps/MinIO";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Users" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              mountpoint = "/mnt/DataStore/Users";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Users/Masood" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              mountpoint = "/mnt/DataStore/Users/Masood";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Users/Tanvir" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              mountpoint = "/mnt/DataStore/Users/Tanvir";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/Media" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "/mnt/DataStore/Media";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/NonBackedUp" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              mountpoint = "/mnt/DataStore/NonBackedUp";
              "com.sun:auto-snapshot" = "true";
            };
          };

          "DataStore/NonBackedUp/PVE-Data" = {
            type = "zfs_fs";

            options = {
              canmount = "on";
              recordsize = "1M";
              mountpoint = "/mnt/DataStore/NonBackedUp/PVE-Data";
              "com.sun:auto-snapshot" = "true";
            };
          };
        };
      };
    };
  };
}
