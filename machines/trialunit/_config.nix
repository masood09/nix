{
  config.homelab = {
    purpose = "Test & Integration Environment";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "trialunit";
      domain = "test.mantannest.com";
    };

    programs = {
      motd = {
        enable = true;

        networkInterfaces = [
          "ens18"
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

      authentik = {
        enable = true;
      };

      babybuddy = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      backup = {
        enable = true;
        extraPaths = ["/var/lib/private/authentik/media"];

        serviceUnits = [
          "authentik.service"
          "authentik-worker.service"
          "garage.service"
          "headscale.service"
          "immich-machine-learning.service"
          "immich-server.service"
          "karakeep-browser.service"
          "karakeep-workers.service"
          "karakeep-web.service"
          "podman-babybuddy.service"
          "podman-opencloud-collabora.service"
          "podman-opencloud-opencloud.service"
          "podman-opencloud-wopi.service"
          "uptime-kuma.service"
          "vaultwarden.service"
        ];
      };

      blocky = {
        enable = true;

        dnsListen = [
          "127.0.0.1:53"
          "10.0.20.4:53"
          "100.64.0.22:53"
        ];

        unbound = {
          localDomain = "mantannest.com";
        };
      };

      caddy = {
        enable = true;
      };

      dell-idrac-fan-controller = {
        enable = true;
      };

      garage = {
        enable = true;

        zfs = {
          enable = true;
          datasetMeta = "dpool/tank/services/garage_meta";
        };
      };

      grafana = {
        enable = true;

        zfs = {
          enable = true;
        };
      };

      headscale = {
        enable = true;

        oidc = {
          enable = true;
        };

        zfs = {
          enable = true;
          dataset = "dpool/tank/services/headscale";
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

        retentionPeriod = {
          default = "24h";
          debug = "24h";
          warn = "48h";
          error = "168h";
        };

        zfs = {
          enable = true;
        };
      };

      opencloud = {
        enable = true;

        zfs = {
          enable = true;
          rootDataset = "dpool/tank/services/opencloud";
          etcDataset = "dpool/tank/services/opencloud-etc";
          idmDataset = "dpool/tank/services/opencloud-idm";
          natsDataset = "dpool/tank/services/opencloud-nats";
          searchDataset = "dpool/tank/services/opencloud-search";
          storageMetaDataset = "dpool/tank/services/opencloud-storage-meta";
          storageOCMDataset = "dpool/tank/services/opencloud-storage-ocm";
          storageUserDataset = "dpool/tank/services/opencloud-storage-user";
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
          dataset = "dpool/tank/services/postgresql_17";
        };

        backup = {
          enable = true;

          zfs = {
            enable = true;
            dataset = "dpool/tank/backup/postgresql";
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

      uptime-kuma = {
        enable = true;

        zfs = {
          enable = true;
          dataset = "dpool/tank/services/uptime-kuma";
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
