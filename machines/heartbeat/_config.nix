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

          properties = {
            recordsize = "1M";
          };
        };
      };

      podman = {
        enable = true;

        zfs = {
          enable = true;

          properties = {
            logbias = "latency";
            recordsize = "16K";
          };
        };
      };

      postgresql = {
        enable = true;
        enableTCPIP = true;

        zfs = {
          enable = true;

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
          properties = {
            recordsize = "16K";
          };
        };
      };

      vaultwarden = {
        enable = true;

        zfs = {
          enable = true;

          properties = {
            logbias = "latency";
            recordsize = "16K";
          };
        };
      };
    };
  };
}
