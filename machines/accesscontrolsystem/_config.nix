{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "accesscontrolsystem";
    };

    services = {
      authentik = {
        enable = true;
      };

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

      postgresql = {
        enable = true;

        zfs = {
          enable = true;
          dataset = "rpool/root/var/lib/postgresql/17";

          properties = {
            compression = "lz4";
            dnodesize = "auto";
            logbias = "latency";
            recordsize = "8K";
            redundant_metadata = "most";
          };
        };

        backup = {
          enable = true;

          zfs = {
            enable = true;
            dataset = "rpool/root/var/backup/postgresql";

            properties = {
              recordsize = "1M";
              dnodesize = "auto";
            };
          };
        };
      };

      restic = {
        enable = true;
        s3Enable = true;

        extraPaths = ["/var/lib/private/authentik/media"];
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
