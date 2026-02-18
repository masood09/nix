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
          "matrix-authentication-service.service"
          "matrix-synapse.service"
          "podman-babybuddy.service"
          "podman-compose-mailarchiver.target"
          "podman-compose-opencloud-root.target"
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

      mailarchiver = {
        enable = true;

        zfs = {
          enable = true;
        };

        protonBridge = {
          enable = true;

          zfs = {
            enable = true;
          };
        };
      };

      matrix = {
        synapse = {
          enable = true;

          listenAddress = [
            "127.0.0.1"
            "100.64.0.21"
          ];

          zfs = {
            enable = true;
          };

          mas = {
            http = {
              trusted_proxies = [
                "100.64.0.14"
              ];

              web = {
                bindAddresses = [
                  "127.0.0.1"
                  "100.64.0.21"
                ];
              };

              health = {
                bindAddresses = [
                  "127.0.0.1"
                  "100.64.0.21"
                ];
              };
            };
          };
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
