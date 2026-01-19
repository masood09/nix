{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;
    isMirroredBoot = true;
    impermanence = true;

    networking = {
      hostName = "heartbeat";
    };

    services = {
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
