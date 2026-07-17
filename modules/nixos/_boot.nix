# Boot configuration — bootloader selection, console log level, kernel params,
# initrd, and Plymouth.
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

        timeout = 3;
      };

      # Plymouth boot splash for non-ZFS desktops (systemd-boot + systemd initrd).
      # Stylix applies Base16 colors to the splash automatically when enabled.
      plymouth = lib.mkIf isDesktopSystemdBoot {
        enable = true;
      };

      # Quiet boot — suppress kernel/udev/systemd messages so the Plymouth
      # splash renders uninterrupted from bootloader through LUKS prompt to
      # greeter.  Messages are still captured in the journal (journalctl -b -k).
      #
      # consoleLogLevel sets the kernel's printk level for the physical console.
      # It MUST be used instead of a "loglevel=N" kernelParam because the NixOS
      # kernel module (nixos/modules/system/boot/kernel.nix) unconditionally
      # appends "loglevel=<consoleLogLevel>" after all kernelParams — the kernel
      # honours the last occurrence, so a kernelParam entry would be silently
      # overridden by the default (4).  Level 3 = KERN_ERR + KERN_CRIT +
      # KERN_ALERT + KERN_EMERG only.
      #
      # Plymouth's NixOS module already adds "splash" to kernelParams, so we
      # don't duplicate it here.  "auto" for show_status prints systemd status
      # lines only on errors or significant delays.
      consoleLogLevel = lib.mkIf isDesktopSystemdBoot 3;

      kernelParams = lib.mkIf isDesktopSystemdBoot [
        "quiet"
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
        systemd = {
          # systemd stage-1 initrd is the default as of nixos-26.05. Non-ZFS
          # desktops additionally rely on it for LUKS unlock via
          # systemd-cryptsetup (Plymouth's password agent integration).
          enable = lib.mkIf isDesktopSystemdBoot true;

          # Roll back root dataset to a blank snapshot on every boot
          # (impermanence). Under systemd stage-1 initrd the scripted
          # postResumeCommands hook is unsupported, so this runs as an initrd
          # oneshot ordered after the pool import and before the root dataset
          # is mounted at /sysroot.
          services = {
            rollback =
              lib.mkIf (
                homelabCfg.isRootZFS
                && homelabCfg.impermanence
              ) {
                description = "Roll back root ZFS dataset to a blank snapshot";
                wantedBy = ["initrd.target"];
                after = ["zfs-import-rpool.service"];
                before = ["sysroot.mount"];
                path = [config.boot.zfs.package];
                unitConfig = {
                  DefaultDependencies = "no";
                };
                serviceConfig = {
                  Type = "oneshot";
                };
                script = ''
                  zfs rollback -r rpool/root/empty@start
                '';
              };
          };
        };

        network = {
          flushBeforeStage2 = true;
        };
      };

      supportedFilesystems = lib.mkIf homelabCfg.isRootZFS ["zfs"];
    };
  };
}
