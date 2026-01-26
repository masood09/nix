{
  config,
  lib,
  ...
}: let
  byId = id: "/dev/disk/by-id/${id}";

  dataIds = config.homelab.disks.data;
  dataDevs = map byId dataIds;

  mkDataDisk = device: {
    type = "disk";
    inherit device;

    content = {
      type = "gpt";
      partitions = {
        data = {
          end = "-1M";
          content = {
            type = "zfs";
            pool = "dpool";
          };
        };
      };
    };
  };

  dataDiskAttrs = lib.listToAttrs (lib.imap0 (i: dev: {
      name = "data${toString (i + 1)}";
      value = mkDataDisk dev;
    })
    dataDevs);

  # Helper for legacy mountpoint datasets
  mkLegacy = mountpoint: opts: {
    type = "zfs_fs";
    inherit mountpoint;
    options = {mountpoint = "legacy";} // opts;
  };
in {
  assertions = [
    {
      assertion = builtins.length dataIds >= 4;
      message = "homelab.disks.data must have at least 4 disks (you have ${toString (builtins.length dataIds)}).";
    }
  ];

  disko.devices = {
    disk = dataDiskAttrs;

    zpool.dpool = {
      type = "zpool";
      mode = "raidz2";

      options = {
        ashift = "12";
        autotrim = "on";
      };

      # Defaults inherited by datasets in this pool
      rootFsOptions = {
        acltype = "posixacl";
        atime = "off";
        canmount = "off";
        compression = "zstd";
        dnodesize = "auto";
        normalization = "formD";
        relatime = "on";
        xattr = "sa";
        "com.sun:auto-snapshot" = "true";
      };

      datasets = {
        "tank" = {
          type = "zfs_fs";

          options = {
            canmount = "off";
            encryption = "aes-256-gcm";
            keylocation = "file:///run/secrets/dpool_tank_key";
            keyformat = "passphrase";
            mountpoint = "none";
            "com.sun:auto-snapshot" = "true";
          };
        };

        "tank/backup" = mkLegacy "/mnt/tank/backup" {};

        "tank/data" = mkLegacy "/mnt/tank/data" {};

        "tank/media" = mkLegacy "/mnt/tank/media" {};

        "tank/services" = mkLegacy "/mnt/tank/services" {};

        "tank/users" = mkLegacy "/mnt/tank/users" {};
      };
    };
  };
}
