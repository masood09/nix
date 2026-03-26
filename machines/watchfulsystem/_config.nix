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
          logo = ../../nix/logos/watchfulsystem.png;
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
