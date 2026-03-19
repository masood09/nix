# Disko layout for single-disk ZFS root — EFI + encrypted rpool with
# impermanence datasets. Desktop role adds a persistent /home dataset.
{
  config,
  lib,
  ...
}: let
  byId = id: "/dev/disk/by-id/${id}";

  rootIds = config.homelab.disks.root;
  isDesktop = config.homelab.role == "desktop";

  # Helper: dataset with legacy mountpoint
  mkLegacy = mountpoint: extra:
    {
      type = "zfs_fs";
      inherit mountpoint;
      options = {mountpoint = "legacy";} // (extra.options or {});
    }
    // (builtins.removeAttrs extra ["options"]);
in {
  assertions = [
    {
      assertion = builtins.length rootIds == 1;
      message = "homelab.disks.root must have exactly 1 disk for single-disk rpool.";
    }
  ];

  disko.devices = {
    disk.root = {
      type = "disk";
      device = byId (builtins.elemAt rootIds 0);
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

      datasets = lib.mkMerge [
        {
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

          # Impermanence: root is rolled back to this blank snapshot on every boot
          "root/empty" = mkLegacy "/" {
            postCreateHook = "zfs snapshot rpool/root/empty@start";
          };

          "root/nix" = mkLegacy "/nix" {};

          "root/nix/persist" = mkLegacy "/nix/persist" {};

          "root/var/backup" = mkLegacy "/var/backup" {};

          "root/var/lib/nixos" = mkLegacy "/var/lib/nixos" {};

          "root/var/log" = mkLegacy "/var/log" {};

          # 10G reservation prevents pool from filling completely (ZFS needs free space)
          "root/reserved" = {
            type = "zfs_fs";
            options = {
              canmount = "off";
              mountpoint = "none";
              refreservation = "10G";
            };
          };
        }
        (lib.mkIf isDesktop {
          "root/home" = mkLegacy "/home" {};
        })
      ];
    };
  };
}
