{
  config.homelab = {
    purpose = "Mesh Networking Control Plane (Headscale)";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "meshcontrol";
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
          "headscale.service"
        ];
      };

      caddy = {
        enable = true;
      };

      headscale = {
        enable = true;

        oidc = {
          enable = true;
        };

        zfs = {
          enable = true;

          properties = {
            logbias = "latency";
            recordsize = "16K";
            redundant_metadata = "most";
          };
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
}
