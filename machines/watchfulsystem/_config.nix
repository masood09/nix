# Homelab options — monitoring server (Uptime Kuma).
{
  config = {
    homelab = {
      purpose = "Monitoring & Service Health (Uptime Kuma)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      hardware = {
        isVM = true;
      };

      networking = {
        hostName = "watchfulsystem";
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

        backup = {
          enable = true;

          # No services are stopped. uptime-kuma keeps its SQLite database in
          # its dataDir, which is the uptime-kuma dataset — so one atomic
          # snapshot captures the db and its journal together, and SQLite
          # recovers on open exactly as it would after a power cut. Stopping it
          # only created a monitoring blind spot during the backup window.
          serviceUnits = [];
        };

        caddy = {
          enable = true;
        };

        tailscale = {
          enable = true;

          zfs = {
            enable = true;
          };
        };

        uptime-kuma = {
          enable = true;

          zfs = {
            enable = true;
          };
        };
      };
    };
  };
}
