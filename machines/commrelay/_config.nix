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

        backup = {
          enable = true;

          serviceUnits = [
            "uptime-kuma.service"
          ];
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
