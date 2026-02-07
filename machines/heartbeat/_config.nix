{
  config.homelab = {
    purpose = "Primary Homelab Core (NAS + Shared Services)";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "heartbeat";
    };

    programs = {
      motd = {
        enable = true;

        networkInterfaces = [
          "eno2"
          "enp1s0f1"
          "tailscale0"
        ];
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
          "immich-machine-learning.service"
          "immich-server.service"
          "karakeep-browser.service"
          "karakeep-workers.service"
          "karakeep-web.service"
          "podman-babybuddy.service"
          "vaultwarden.service"
        ];
      };

      caddy = {
        enable = true;
      };

      dell-idrac-fan-controller = {
        enable = true;
      };

      grafana = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      immich = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      ittools = {
        enable = true;
      };

      jobscraper = {
        enable = true;
      };

      karakeep = {
        enable = true;

        zfs.enable = true;
      };

      loki = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      opencloud = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      podman = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      postgresql = {
        enable = true;
        enableTCPIP = true;

        zfs = {
          enable = true;
        };

        backup = {
          enable = true;

          zfs = {
            enable = true;
          };
        };
      };

      prometheus = {
        enable = true;
        zfs.enable = true;
      };

      tailscale = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      vaultwarden = {
        enable = true;

        zfs = {
          enable = true;
        };
      };
    };
  };
}
