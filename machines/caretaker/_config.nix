{
  config.homelab = {
    purpose = "Core Network Services (DNS Filtering + UPS Monitoring)";
    isRootZFS = false;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "caretaker";
    };

    programs = {
      motd.enable = true;
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
