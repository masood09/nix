{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;

    networking = {
      hostName = "meshcontrol";
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

      headscale = {
        enable = true;

        oidc = {
          enable = true;
        };

        zfs = {
          enable = true;
          dataset = "rpool/root/var/lib/headscale";

          properties = {
            logbias = "latency";
            recordsize = "16K";
            redundant_metadata = "most";
          };
        };
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
    };
  };
}
