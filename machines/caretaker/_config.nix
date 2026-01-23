{
  config.homelab = {
    isRootZFS = false;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "caretaker";
    };

    services = {
      blocky = {
        enable = true;
      };

      tailscale = {
        enable = true;
      };
    };
  };
}
