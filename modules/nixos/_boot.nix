# Boot configuration — bootloader selection, kernel params, and initrd setup.
# Automatically chooses between systemd-boot (non-ZFS) and GRUB (ZFS),
# with support for mirrored boot partitions on multi-disk setups.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options = {
    homelab = {
      isEncryptedRoot = lib.mkOption {
        default = true;
        type = lib.types.bool;
      };

      isMirroredBoot = lib.mkEnableOption "Whether its mirrored boot";
    };
  };

  config = {
    # Auto-detect mirrored boot from disk count (>1 root disk = mirrored)
    homelab = {
      isMirroredBoot = lib.mkDefault (
        (builtins.length (config.homelab.disks.root or [])) > 1
      );
    };

    boot = {
      loader = {
        # Non-ZFS machines use systemd-boot (simpler, no GRUB needed)
        systemd-boot = lib.mkIf (!homelabCfg.isRootZFS) {
          enable = true;
          configurationLimit = 7;
        };

        # ZFS machines use GRUB with EFI + ZFS support
        efi = lib.mkIf homelabCfg.isRootZFS {
          efiSysMountPoint = "/boot";
        };

        generationsDir = lib.mkIf homelabCfg.isRootZFS {
          copyKernels = true;
        };

        grub = lib.mkIf homelabCfg.isRootZFS {
          enable = true;
          configurationLimit = 7;
          efiInstallAsRemovable = true;
          copyKernels = true;
          efiSupport = true;
          zfsSupport = true;

          devices = lib.mkIf (!homelabCfg.isMirroredBoot) ["nodev"];

          gfxmodeEfi = "text";

          extraConfig = ''
            terminal_output console
          '';

          # Mirror GRUB across both disks so either can boot independently
          mirroredBoots = lib.mkIf homelabCfg.isMirroredBoot [
            {
              devices = ["nodev"];
              path = "/boot";
            }
            {
              devices = ["nodev"];
              path = "/boot-mirror";
            }
          ];
        };

        timeout = 10;
      };

      # IPv6 disabled across the homelab
      kernel = {
        sysctl = {
          "net.ipv6.conf.all.disable_ipv6" = 1;
          "net.ipv6.conf.default.disable_ipv6" = 1;
          "net.ipv6.conf.lo.disable_ipv6" = 1;
        };
      };

      initrd = {
        network = {
          flushBeforeStage2 = true;
        };

        # Roll back root dataset to blank snapshot on every boot (impermanence)
        postResumeCommands =
          lib.mkIf (
            homelabCfg.isRootZFS
            && homelabCfg.impermanence
          )
          (lib.mkAfter ''
            zfs rollback -r rpool/root/empty@start
          '');
      };

      supportedFilesystems = lib.mkIf homelabCfg.isRootZFS ["zfs"];
    };
  };
}
