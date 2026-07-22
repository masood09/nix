# Homelab options — test environment (Proxmox VM, test.mantannest.com domain).
{
  config = {
    homelab = {
      purpose = "Test & Integration Environment";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      hardware = {
        isVM = true;
      };

      networking = {
        hostName = "trialunit";
        domain = "test.mantannest.com";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool" "dpool"];
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
          # The whole StateDirectory, not .../media — see the same change on
          # accesscontrolsystem. media/ only exists once something has been
          # uploaded, and restic silently skips missing paths, so this entry had
          # been backing up nothing. Neither host has a media/ directory today.
          extraPaths = ["/var/lib/private/authentik"];

          # authentik, authentik-worker, headscale and headplane are
          # deliberately absent — they were removed for the same reasons they
          # were removed on accesscontrolsystem and meshcontrol, and because
          # together they reproduced the 02:00 headscale outage on a single
          # host.
          #
          # headscale sets only_start_if_oidc_is_available and exits fatally
          # when its issuer is unreachable at startup. This stop-list restarted
          # authentik and headscale together, and headscale came back before
          # authentik was serving OIDC, so on 2026-07-22 it crash-looped three
          # times against "503 Service Unavailable: authentik starting" before
          # recovering at 02:01:14. Not restarting headscale removes the
          # coupling; the cross-host version of this same failure is described
          # in machines/meshcontrol/_config.nix.
          #
          # Neither needs quiescing anyway. headscale and headplane each keep
          # all state in a single ZFS dataset (headscale is SQLite with
          # write_ahead_log = true, and db/-wal/-shm all live under
          # /var/lib/headscale, which is the dataset mountpoint), so one atomic
          # snapshot is crash-consistent. authentik has no dataset at all: its
          # state is the PostgreSQL dump, which pg_dump makes MVCC-consistent
          # without help, plus an extraPath that restic reads live after
          # services are already back up.
          serviceUnits = [
            "garage.service"
            "immich-machine-learning.service"
            "immich-server.service"
            "karakeep-browser.service"
            "karakeep-workers.service"
            "karakeep-web.service"
            "mailarchiver.service"
            "matrix-authentication-service.service"
            "matrix-synapse.service"
            "nightscout.service"
            "podman-babybuddy.service"
            "podman-compose-opencloud-root.target"
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

          headplane = {
            zfs = {
              enable = true;
              dataset = "dpool/tank/services/headplane";
            };
          };

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

          zfs = {
            enable = true;
          };
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

        mailarchiver = {
          enable = true;

          zfs = {
            enable = true;
            dataset = "dpool/tank/services/mailarchiver";
          };
        };

        matrix = {
          synapse = {
            enable = true;
            enableCaddy = true;

            zfs = {
              enable = true;

              dataDir = {
                dataset = "dpool/tank/services/matrix-synapse";
              };
            };
          };

          rtc = {
            enable = true;
          };
        };

        mongodb = {
          enable = true;

          zfs = {
            enable = true;
            dataset = "dpool/tank/services/mongodb";
          };
        };

        nightscout = {
          enable = true;
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
          retentionTime = "2d";

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
  };
}
