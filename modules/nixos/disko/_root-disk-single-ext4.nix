# Disko layout for single-disk LUKS+ext4 — non-ZFS counterpart to
# _root-disk-single.nix. Intended for desktops that want systemd-boot
# and Plymouth (both impossible with ZFS root, which requires GRUB).
#
# Partition layout:
#   GPT
#   ├─ EFI   1 GiB   vfat   → /boot
#   └─ LUKS  (rest)  cryptroot  (allowDiscards for SSD TRIM)
#      └─ LVM  vg
#         ├─ swap  40 GiB   linux-swap  (resumeDevice for hibernate)
#         └─ nix   (rest)   ext4        → /nix
#
# Root (/) is tmpfs, wiped on every reboot.  Persistent state lives
# under /nix/persist via the impermanence module (see _impermanence.nix).
{
  config,
  lib,
  ...
}: let
  byId = id: "/dev/disk/by-id/${id}";

  rootIds = config.homelab.disks.root;
in {
  assertions = [
    {
      assertion = builtins.length rootIds == 1;
      message = "homelab.disks.root must have exactly 1 disk for single-disk ext4 layout.";
    }
  ];

  disko = {
    devices = {
      # tmpfs root — wiped on every reboot (impermanence without ZFS rollback)
      nodev = {
        "/" = {
          fsType = "tmpfs";
          mountOptions = ["defaults" "size=20G" "mode=0755"];
        };
      };

      disk = {
        root = {
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
                size = "100%";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  settings = {
                    # Required for SSD TRIM to pass through the LUKS layer
                    allowDiscards = true;
                  };
                  content = {
                    type = "lvm_pv";
                    vg = "vg";
                  };
                };
              };
            };
          };
        };
      };

      # LVM inside LUKS — single passphrase unlocks both swap and nix
      lvm_vg = {
        vg = {
          type = "lvm_vg";
          lvs = {
            swap = {
              size = "40G";
              content = {
                type = "swap";
                # Tells NixOS to set boot.resumeDevice, required for hibernate
                resumeDevice = true;
              };
            };

            nix = {
              size = "100%FREE";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/nix";
              };
            };
          };
        };
      };
    };
  };
}
