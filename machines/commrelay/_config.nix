# Homelab options — federated messaging server (Matrix Synapse + LiveKit RTC).
{
  config = {
    homelab = {
      purpose = "Secure, federated real-time messaging and identity-aware communication hub (Matrix Synapse).";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "commrelay";
      };

      programs = {
        motd = {
          enable = true;

          networkInterfaces = [
            "enp0s6"
            "tailscale0"
          ];
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
