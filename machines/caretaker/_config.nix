# Homelab options — core network services (Blocky DNS + NUT UPS).
{
  config = {
    homelab = {
      purpose = "Core Network Services (DNS Filtering + UPS Monitoring)";
      isRootZFS = false;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "caretaker";
      };

      programs = {
        fastfetch = {};
      };

      services = {
        backup = {
          enable = true;
          # No services need stopping — blocky handles DNS restarts gracefully
          serviceUnits = [];
        };

        blocky = {
          enable = true;
        };

        tailscale = {
          enable = true;
        };
      };
    };
  };
}
