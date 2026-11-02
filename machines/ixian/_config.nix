# Homelab options — headless-first AI inference and gaming PC.
{pkgs, ...}: {
  config = {
    boot = {
      initrd = {
        luks = {
          devices = {
            # The model disk is unlocked after /nix is mounted, using a key
            # stored on the encrypted root filesystem. This keeps boot to one
            # passphrase while retaining independent LUKS volumes.
            cryptmodels = {
              crypttabExtraOpts = [
                "noauto"
              ];
            };
          };
        };
      };
    };

    homelab = {
      role = "server";
      purpose = "AI Inference and Gaming PC (Headless Base)";
      isRootZFS = false;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "ixian";
      };

      services = {
        # Monitoring will be added after the base system and secret lifecycle
        # are established for this new machine.
        alloy = {
          enable = false;
        };
      };

      # Install the AMD graphics/compute driver stack without enabling a
      # graphical login, compositor, or desktop session.
      hardware = {
        graphics = {
          enable = true;
          driver = "amd";
        };
      };

      desktop = {
        enable = false;
      };
    };

    systemd = {
      services = {
        cryptmodels-unlock = {
          description = "Unlock ixian model storage from the root-resident key";
          wantedBy = [
            "srv-models.mount"
          ];
          before = [
            "srv-models.mount"
          ];
          after = [
            "nix.mount"
          ];
          requires = [
            "nix.mount"
          ];
          path = [
            pkgs.cryptsetup
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            if cryptsetup status cryptmodels >/dev/null 2>&1; then
              exit 0
            fi

            cryptsetup open \
              --key-file /nix/secret/ixian-models.key \
              /dev/disk/by-partlabel/disk-models-models \
              cryptmodels
          '';
        };
      };
    };
  };
}
