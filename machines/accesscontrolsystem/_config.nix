{
  config.homelab = {
    purpose = "Identity & Access Control (SSO / Authentik)";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "accesscontrolsystem";
    };

    programs = {
      motd = {
        enable = true;

        networkInterfaces = [
          "enp0s6"
          "tailscale0"
        ];
      };
    };

    services = {
      authentik = {
        enable = true;
      };

      acme = {
        zfs = {
          enable = true;
        };
      };

      backup = {
        enable = true;

        extraPaths = ["/var/lib/private/authentik/media"];
      };

      caddy = {
        enable = true;
      };

      postgresql = {
        enable = true;

        zfs = {
          enable = true;
          dataset = "rpool/root/var/lib/postgresql/17";
        };

        backup = {
          enable = true;

          zfs = {
            enable = true;
            dataset = "rpool/root/var/backup/postgresql";
          };
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
}
