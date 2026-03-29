# Homelab options — mesh networking control plane (Headscale + Headplane).
{
  config = {
    homelab = {
      purpose = "Mesh Networking Control Plane (Headscale)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      hardware = {
        isVM = true;
      };

      networking = {
        hostName = "meshcontrol";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
      };

      services = {
        acme = {
          zfs = {
            enable = true;
          };
        };

        backup = {
          enable = true;

          serviceUnits = [
            "headplane.service"
            "headscale.service"
          ];
        };

        caddy = {
          enable = true;
        };

        headscale = {
          enable = true;

          oidc = {
            enable = true;
          };

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
  };
}
