{
  config.homelab = {
    isRootZFS = false;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "caretaker";
    };

    services = {
      tailscale = {
        enable = true;
      };
    };
  };
}
