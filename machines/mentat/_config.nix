# Homelab options — secondary DNS (Blocky + Unbound). Hermes agent is a later
# phase; phase 1 is just a booting ZFS host serving DNS.
{
  config = {
    homelab = {
      purpose = "Secondary DNS (DNS Filtering) & Hermes Agent";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "mentat";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
      };

      services = {
        # Disabled for phase 1: Blocky's config is fully declarative and
        # tailscale's node state is re-creatable, so there is nothing worth
        # backing up yet. Enable (with restic secrets) when Hermes lands.
        backup = {
          enable = false;
        };

        # Same setup as caretaker (primary): listen on :53, Unbound upstream.
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

          zfs = {
            enable = true;
          };
        };
      };
    };
  };
}
