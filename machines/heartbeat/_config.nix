# Homelab options — primary server (NAS + shared services on Dell R730xd).
{config, ...}: {
  config = {
    homelab = {
      purpose = "Primary Homelab Core (NAS + Shared Services)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "heartbeat";
      };

      # Intel i5-8500T UHD 630 iGPU — VAAPI/QuickSync for Jellyfin hardware transcoding
      # (homelab.services.arr.jellyfin.hardwareAcceleration).
      hardware = {
        graphics = {
          enable = true;
          driver = "intel";
        };
      };

      programs = {
        fastfetch = {
          zpools = [
            "rpool"
            "fpool"
            "dpool"
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
            "mailarchiver.service"
            "matrix-authentication-service.service"
            "matrix-synapse.service"
            "minecraft-server-forever.service"
            "minecraft-server-velocity.service"
            "nightscout.service"
            "podman-babybuddy.service"
            "podman-compose-opencloud-root.target"
            "vaultwarden.service"
          ];
        };

        arr = {
          enable = true;

          jellyfin = {
            enable = true;

            ldap = {
              enable = true;
              server = "ldap.authentik.mantannest.com";
              baseDn = "dc=ldap,dc=mantannest,dc=com";
              bindDn = "cn=jellyfin-ldap-bind,ou=users,dc=ldap,dc=mantannest,dc=com";
              accessGroups = ["kids" "parents" "homelab-admins"];
              adminGroup = "homelab-admins";
            };
          };

          sonarr = {
            enable = true;
          };

          radarr = {
            enable = true;
          };

          prowlarr = {
            enable = true;
          };

          sabnzbd = {
            enable = true;
          };

          recyclarr = {
            enable = true;
          };

          seerr = {
            enable = true;
          };

          # Frugal Usenet, per their own newsreader setup guide (billing.frugalusenet.com/page/newsreader):
          # primary server 50-75 connections recommended for optimal speeds (up to 100
          # allowed) on a fast line, EU server as ~30-connection insurance ("will likely
          # not provide much traffic"), bonus server separate system with a 1000GB/month
          # cap, lower priority.
          usenetProviders = [
            {
              name = "FrugalUsenet";
              host = "news.frugalusenet.com";
              port = 563;
              ssl = true;
              connections = 75;
              retention = 4000;
              priority = 0;
              username = {
                _secret = config.sops.secrets."arr/usenet/frugalusenet/username".path;
              };
              password = {
                _secret = config.sops.secrets."arr/usenet/frugalusenet/password".path;
              };
            }
            {
              name = "FrugalUsenet (EU backup)";
              host = "eunews.frugalusenet.com";
              port = 563;
              ssl = true;
              connections = 30;
              retention = 4000;
              priority = 1;
              backup = true;
              username = {
                _secret = config.sops.secrets."arr/usenet/frugalusenet/username".path;
              };
              password = {
                _secret = config.sops.secrets."arr/usenet/frugalusenet/password".path;
              };
            }
            {
              name = "FrugalUsenet (bonus)";
              host = "bonus.frugalusenet.com";
              port = 563;
              ssl = true;
              connections = 20;
              retention = 4000;
              priority = 2;
              backup = true;
              username = {
                _secret = config.sops.secrets."arr/usenet/frugalusenet/username".path;
              };
              password = {
                _secret = config.sops.secrets."arr/usenet/frugalusenet/password".path;
              };
            }
          ];

          indexers = [
            {
              name = "NZBgeek";
              apiKey = {
                _secret = config.sops.secrets."arr/indexers/nzbgeek/api-key".path;
              };
            }
            {
              name = "NzbPlanet";
              apiKey = {
                _secret = config.sops.secrets."arr/indexers/nzbplanet/api-key".path;
              };
            }
          ];
        };

        caddy = {
          enable = true;
        };

        dell-idrac-fan-controller = {
          enable = true;
        };

        # Hardware health for this bare-metal Supermicro box: per-disk SMART
        # (8× 14TB HDD + SSDs + NVMe) and local BMC sensors (temps, fans, PSU).
        smartctl-exporter = {
          enable = true;
        };

        ipmi-exporter = {
          enable = true;
        };

        grafana = {
          enable = true;

          discord = {
            enable = true;
          };

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
          openFirewall = true;

          zfs = {
            enable = true;
          };
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

        minecraft = {
          enable = true;
          openFirewall = true;

          zfs = {
            enable = true;
            dataset = "fpool/fast/services/minecraft";
          };
        };

        mongodb = {
          enable = true;

          zfs = {
            enable = true;
          };
        };

        nightscout = {
          enable = true;
          listenAddress = "0.0.0.0";
          openFirewall = true;
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
