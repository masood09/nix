{
  config,
  lib,
  ...
}: let
  rdisk = lib.elemAt config.homelab.disks.root 0;

  # Helper: dataset with legacy mountpoint
  mkLegacy = mountpoint: extra: ({
      type = "zfs_fs";
      inherit mountpoint;
      options = {mountpoint = "legacy";} // (extra.options or {});
    }
    // (builtins.removeAttrs extra ["options"]));
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
  };
}
