{
  config.homelab = {
    isRootZFS = true;
    isEncryptedRoot = true;

    networking = {
      hostName = "meshcontrol";
    };

    services = {
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
