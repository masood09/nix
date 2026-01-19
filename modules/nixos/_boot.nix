{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  options.homelab = {
    isEncryptedRoot = lib.mkOption {
      default = true;
      type = lib.types.bool;
    };

    isMirroredBoot = lib.mkEnableOption "Whether its mirrored boot";
  };

  config = {
    homelab.isMirroredBoot = lib.mkDefault (
      (builtins.length (config.homelab.disks.root or [])) > 1
    );

    boot = {
      loader = {
        systemd-boot = lib.mkIf (!homelabCfg.isRootZFS) {
          enable = true;
          configurationLimit = 7;
        };

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

      kernel.sysctl = {
        "net.ipv6.conf.all.disable_ipv6" = 1;
        "net.ipv6.conf.default.disable_ipv6" = 1;
        "net.ipv6.conf.lo.disable_ipv6" = 1;
      };

      initrd = {
        network = {
          flushBeforeStage2 = true;
        };

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
