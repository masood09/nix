{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;

    networking = {
      hostName = "watchfulsystem";
    };

    services = {
      acme = {
        zfs = {
          enable = true;
          dataset = "rpool/root/var/lib/acme";
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
          dataset = "rpool/root/var/lib/tailscale";
          properties = {
            recordsize = "16K";
          };
        };
      };

      uptime-kuma = {
        enable = true;

        zfs = {
          enable = true;
          dataset = "rpool/root/var/lib/uptime-kuma";
          properties = {
            recordsize = "16K";
          };
        };
      };
    };
  };
}
