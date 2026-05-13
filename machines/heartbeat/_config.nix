# Homelab options — primary server (NAS + shared services on Dell R730xd).
{
  config = {
    homelab = {
      purpose = "Primary Homelab Core (NAS + Shared Services)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "heartbeat";
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
            "minecraft-server.service"
            "nightscout.service"
            "podman-babybuddy.service"
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
          enableCommandBlocks = true;
          difficulty = "peaceful";
          functionPermissionLevel = 4;
          motd = "Aswesome Minecraft Server";
          onlineMode = false;
          # Vanilla Minecraft has no operator wildcard; add each offline-mode
          # player UUID here if they should be able to run commands.
          operators = {
            Masood = "c7c4eeb6-cd39-32bf-86e4-66764d831b95";
          };
          operatorPermissionLevel = 4;
          openFirewall = true;
          # Heartbeat runs a low-conflict exploration world with hostile mobs off.
          spawnMonsters = false;
          spawnProtection = 0;
          seed = "8491026976556481134";
          viewDistance = 16;
          worldName = "myworld";

          minecraft2 = {
            enable = true;
            enableCommandBlocks = true;
            dataDir = "/var/lib/minecraft2";
            difficulty = "peaceful";
            functionPermissionLevel = 4;
            groupId = 3015;
            motd = "Forever Minecraft Server";
            onlineMode = false;
            # Keep command access explicit because offline-mode UUIDs depend on
            # the exact username used by each client.
            operators = {
              Masood = "c7c4eeb6-cd39-32bf-86e4-66764d831b95";
            };
            operatorPermissionLevel = 4;
            openFirewall = true;
            port = 25566;
            seed = "-3482801611578790576";
            spawnMonsters = false;
            spawnProtection = 0;
            userId = 3015;
            viewDistance = 16;
            worldName = "world";

            zfs = {
              enable = true;
              dataset = "dpool/tank/services/minecraft2";
            };
          };

          zfs = {
            enable = true;
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
