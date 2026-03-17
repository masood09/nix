{
  config.homelab = {
    role = "desktop";
    purpose = "Primary Laptop (NixOS Desktop)";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "commandmodule";
      wireless_enable = true;
    };

    programs = {
      motd = {
        enable = true;

        networkInterfaces = [
          "enp0s31f6"
          "wlp0s20f3"
        ];
      };
    };
  };
}
