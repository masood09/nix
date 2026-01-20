{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "heartbeat";
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

      immich = {
        enable = true;

        zfs = {
          enable = true;
          dataset = "dpool/tank/services/immich";

          properties = {
            recordsize = "1M";
          };
        };
      };

      postgresql = {
        enable = true;
        enableTCPIP = true;

        zfs = {
          enable = true;
          dataset = "fpool/fast/services/postgresql_17";

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
          dataDir = "/mnt/fast/backup/postgresql";

          zfs = {
            enable = true;
            dataset = "fpool/fast/backup/postgresql";

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

      vaultwarden = {
        enable = true;

        zfs = {
          enable = true;
          dataset = "dpool/tank/services/vaultwarden";

          properties = {
            logbias = "latency";
            recordsize = "16K";
          };
        };
      };
    };
  };
}
