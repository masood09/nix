# Homelab options — core network services (Blocky DNS + NUT UPS).
{
  config = {
    homelab = {
      purpose = "Core Network Services (DNS Filtering + UPS Monitoring)";
      isRootZFS = false;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "caretaker";
      };

      programs = {
        fastfetch = {};
      };

      services = {
        # Disabled: nothing to back up. This host has no ZFS datasets and no
        # PostgreSQL, so the pipeline generated no restic job and the nightly
        # run was a no-op that still logged "Backup pipeline complete".
        # Blocky's config is fully declarative, so there is no state to keep.
        backup = {
          enable = false;
        };

        blocky = {
          enable = true;
        };

        # Bare-metal host with a single NVMe: per-disk SMART health. No BMC, so
        # no IPMI exporter here.
        smartctl-exporter = {
          enable = true;
        };

        tailscale = {
          enable = true;
        };
      };
    };
  };
}
