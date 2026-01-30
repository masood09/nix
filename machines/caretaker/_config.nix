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
      motd = {
        enable = true;

        networkInterfaces = [
          "enp1s0"
          "tailscale0"
        ];
      };
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
