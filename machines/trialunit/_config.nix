{
  config.homelab = {
    purpose = "Test & Integration Environment";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "trialunit";
    };

    programs = {
      motd = {
        enable = true;

        networkInterfaces = [
          "ens18"
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

      rebootRequiredCheck.enable = true;

      tailscale = {
        enable = true;

        zfs = {
          enable = true;
        };
      };
    };
  };
}
