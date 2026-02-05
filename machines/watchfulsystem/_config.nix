{
  config.homelab = {
    purpose = "Monitoring & Service Health (Uptime Kuma)";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "watchfulsystem";
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

      blocky = {
        enable = true;

        dnsListen = [
          "100.64.0.24:53"
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
}
