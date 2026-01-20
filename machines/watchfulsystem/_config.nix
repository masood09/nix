{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "watchfulsystem";
    };

    services = {
      acme = {
        zfs = {
          enable = true;
          properties = {
            recordsize = "16K";
          };
        };
      };

      caddy = {
        enable = true;
      };

      restic = {
        enable = true;
        s3Enable = true;
      };

      tailscale = {
        enable = true;

        zfs = {
          enable = true;
          properties = {
            recordsize = "16K";
          };
        };
      };

      uptime-kuma = {
        enable = true;

        zfs = {
          enable = true;
          properties = {
            recordsize = "16K";
          };
        };
      };
    };
  };
}
