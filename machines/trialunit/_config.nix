{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "trialunit";
    };

    services = {
      tailscale = {
        enable = true;

        zfs = {
          enable = true;
        };
      };
    };
  };
}
