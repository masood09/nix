{
  config,
  lib,
  ...
}: let
  byId = id: "/dev/disk/by-id/${id}";

  fastIds = config.homelab.disks.fast;
  fastDevs = map byId fastIds;

  mkFastDisk = device: {
    type = "disk";
    inherit device;

    content = {
      type = "gpt";
      partitions = {
        fast = {
          end = "-1M";
          content = {
            type = "zfs";
            pool = "fpool";
          };
        };
      };
    };
  };

  fastDiskAttrs = lib.listToAttrs (lib.imap0 (i: dev: {
      name = "fast${toString (i + 1)}";
      value = mkFastDisk dev;
    })
    fastDevs);

  # Helper for legacy mountpoint datasets
  mkLegacy = mountpoint: opts: {
    type = "zfs_fs";
    inherit mountpoint;
    options = {mountpoint = "legacy";} // opts;
  };
in {
  assertions = [
    {
      assertion = builtins.length fastIds == 2;
      message = "homelab.disks.fast must have exactly 2 disks (mirror) for fpool.";
    }
  ];

  disko.devices = {
    disk = fastDiskAttrs;

    zpool.fpool = {
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

      datasets = {
        "fast" = {
          type = "zfs_fs";

          options = {
            canmount = "off";
            encryption = "aes-256-gcm";
            keylocation = "file:///run/secrets/fpool_fast_key";
            keyformat = "passphrase";
            mountpoint = "none";
            "com.sun:auto-snapshot" = "true";
          };
        };

        "fast/backup" = mkLegacy "/mnt/fast/backup" {};

        "fast/data" = mkLegacy "/mnt/fast/data" {};

        "fast/media" = mkLegacy "/mnt/fast/media" {};

        "fast/services" = mkLegacy "/mnt/fast/services" {};

        "fast/users" = mkLegacy "/mnt/fast/users" {};
      };
    };
  };
}
