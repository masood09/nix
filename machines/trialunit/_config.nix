{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "trialunit";
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

      opencloud = {
        enable = true;
        webDomain = "cloud.test.mantannest.com";

        zfs = {
          enable = true;
          rootDataset = "dpool/tank/services/opencloud";
          etcDataset = "dpool/tank/services/opencloud-etc";
          idmDataset = "dpool/tank/services/opencloud-idm";
          natsDataset = "dpool/tank/services/opencloud-nats";
          searchDataset = "dpool/tank/services/opencloud-search";
          storageMetaDataset = "dpool/tank/services/opencloud-storage-meta";
          userStorageDataset = "dpool/tank/services/opencloud-user-storage";
        };
      };

      podman = {
        enable = true;

        zfs = {
          enable = true;
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
