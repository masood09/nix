# Boot configuration — bootloader selection, kernel params, initrd, and Plymouth.
# Automatically chooses between systemd-boot (non-ZFS) and GRUB (ZFS),
# with support for mirrored boot partitions on multi-disk setups.
# Desktops get graphical GRUB; servers stay text-only.
# Non-ZFS desktops get Plymouth with systemd initrd for seamless LUKS unlock.
{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  isDesktopSystemdBoot = homelabCfg.role == "desktop" && !homelabCfg.isRootZFS;
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

          # Graphical framebuffer on desktops (needed for Plymouth); text on servers
          gfxmodeEfi =
            if homelabCfg.role == "desktop"
            then "auto"
            else "text";

          extraConfig = lib.mkIf (homelabCfg.role != "desktop") ''
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

      # Plymouth boot splash for non-ZFS desktops (systemd-boot + systemd initrd).
      # Stylix (_stylix.nix) applies Base16 colors to the splash automatically.
      plymouth = lib.mkIf isDesktopSystemdBoot {
        enable = true;
      };

      # Quiet boot for Plymouth — suppress kernel and udev messages so the
      # splash renders uninterrupted from bootloader through LUKS prompt to greeter.
      # "auto" for show_status prints only on errors or significant delays.
      kernelParams = lib.mkIf isDesktopSystemdBoot [
        "quiet"
        "splash"
        "loglevel=3"
        "rd.udev.log_level=3"
        "systemd.show_status=auto"
        "rd.systemd.show_status=auto"
      ];

      # IPv6 disabled across the homelab
      kernel = {
        sysctl = {
          "net.ipv6.conf.all.disable_ipv6" = 1;
          "net.ipv6.conf.default.disable_ipv6" = 1;
          "net.ipv6.conf.lo.disable_ipv6" = 1;
        };
      };

      initrd = {
        # systemd-based initrd for LUKS unlock via systemd-cryptsetup —
        # required for Plymouth's password agent integration
        systemd = lib.mkIf isDesktopSystemdBoot {
          enable = true;
        };

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
