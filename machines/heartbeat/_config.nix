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
        };
      };

      babybuddy = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      caddy = {
        enable = true;
      };

      immich = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      ittools = {
        enable = true;
      };

      loki = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      podman = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      postgresql = {
        enable = true;
        enableTCPIP = true;

        zfs = {
          enable = true;
        };

        backup = {
          enable = true;

          zfs = {
            enable = true;
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
        };
      };

      vaultwarden = {
        enable = true;

        zfs = {
          enable = true;
        };
      };
    };
  };
}
