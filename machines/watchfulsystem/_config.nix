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
