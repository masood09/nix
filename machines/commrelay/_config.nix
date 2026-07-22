# Homelab options — federated messaging server (Matrix Synapse + LiveKit RTC).
{
  config = {
    homelab = {
      purpose = "Secure, federated real-time messaging and identity-aware communication hub (Matrix Synapse).";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      hardware = {
        isVM = true;
      };

      networking = {
        hostName = "commrelay";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
      };

      services = {
        acme = {
          zfs = {
            enable = true;
          };
        };

        # Disabled: there is nothing here to back up. Both ZFS datasets (acme,
        # tailscale) opt out of restic, so `hasResticPaths` is false and no
        # restic job is ever generated; PostgreSQL is not enabled either. The
        # nightly run stopped nothing, dumped nothing, and still logged
        # "Backup pipeline complete", which read as coverage in log reviews.
        # ACME certs regenerate on demand and the tailscale node can re-auth.
        backup = {
          enable = false;
        };

        caddy = {
          enable = true;
        };

        matrix = {
          openFirewall = true;

          rtc = {
            enable = true;
          };
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
