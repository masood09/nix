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
