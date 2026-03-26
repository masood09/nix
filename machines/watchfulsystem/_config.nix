# Homelab options — monitoring server (Uptime Kuma).
{
  config = {
    homelab = {
      purpose = "Monitoring & Service Health (Uptime Kuma)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

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

          serviceUnits = [
            "uptime-kuma.service"
          ];
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
