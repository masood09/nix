{
  config.homelab = {
    purpose = "Test & Integration Environment";
    isRootZFS = true;
    isEncryptedRoot = true;
    impermanence = true;

    networking = {
      hostName = "trialunit";
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
        webDomain = "auth.test.mantannest.com";
      };

      babybuddy = {
        enable = true;
        webDomain = "babybuddy.test.mantannest.com";

        zfs = {
          enable = true;
        };
      };

      blocky = {
        enable = true;
        dnsPort = 54;
      };

      caddy = {
        enable = true;
      };

      garage = {
        enable = true;
        s3Domain = "s3.test.mantannest.com";

        zfs = {
          enable = true;
          datasetMeta = "dpool/tank/services/garage_meta";
        };
      };

      grafana = {
        enable = true;
        webDomain = "grafana.test.mantannest.com";

        oauth = {
          providerHost = "auth.test.mantannest.com";
          clientId = "grafana";
          roleAttributePath = "contains(groups, 'homelab-admins') && 'Admin' || 'Viewer'";
        };

        zfs = {
          enable = true;
        };
      };

      headscale = {
        enable = true;
        webDomain = "headscale.test.mantannest.com";

        oidc = {
          enable = true;
          issuer = "https://auth.test.mantannest.com/application/o/headscale/";
          client_id = "headscale";
        };

        zfs = {
          enable = true;
          dataset = "dpool/tank/services/headscale";

          properties = {
            logbias = "latency";
            recordsize = "16K";
            redundant_metadata = "most";
          };
        };
      };

      immich = {
        enable = true;
        webDomain = "photos.test.mantannest.com";

        zfs = {
          enable = true;
        };
      };

      ittools = {
        enable = true;
        webDomain = "ittools.test.mantannest.com";
      };

      loki = {
        enable = true;
        webDomain = "loki.test.mantannest.com";

        zfs = {
          enable = true;
        };
      };

      opencloud = {
        enable = true;
        webDomain = "cloud.test.mantannest.com";

        zfs = {
          enable = true;
          rootDataset = "dpool/tank/services/opencloud";
          etcDataset = "dpool/tank/services/opencloud-etc";
          idmDataset = "dpool/tank/services/opencloud-idm";
          natsDataset = "dpool/tank/services/opencloud-nats";
          searchDataset = "dpool/tank/services/opencloud-search";
          storageMetaDataset = "dpool/tank/services/opencloud-storage-meta";
          userStorageDataset = "dpool/tank/services/opencloud-user-storage";
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
        webDomain = "prometheus.test.mantannest.com";
        zfs.enable = true;
      };

      rebootRequiredCheck.enable = true;

      restic = {
        enable = true;
        s3Enable = true;

        extraPaths = ["/var/lib/private/authentik/media"];
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
