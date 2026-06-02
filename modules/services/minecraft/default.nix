# Minecraft — Java Edition stack managed by nix-minecraft.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.minecraft;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};

  minecraftPackages = inputs.nix-minecraft.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  dataDir = "/srv/minecraft";
  publicPort = 25565;
  # awesomeServerPort = 25566;
  # foreverServerPort = 25567;
  ourworldServerPort = 25568;

  serverNames = [
    "velocity"
    "ourworld"
    # "awesome"
    # "forever"
  ];

  serviceNames = map (name: "minecraft-server-${name}") serverNames;
  serverDataDirs = map (name: "${dataDir}/${name}") serverNames;

  serverProperties = {
    # awesome = {
    #   server-ip = "127.0.0.1";
    #   server-port = awesomeServerPort;
    #   gamemode = "survival";
    #   difficulty = "peaceful";
    #   motd = "Awesome Minecraft Server";
    #   "online-mode" = false;
    #   level-name = "myworld";
    #   level-seed = "8491026976556481134";
    #   max-players = 20;
    #   white-list = false;
    #   enable-command-block = true;
    #   function-permission-level = 4;
    #   op-permission-level = 4;
    #   spawn-protection = 0;
    #   view-distance = 12;
    # };

    # forever = {
    #   server-ip = "127.0.0.1";
    #   server-port = foreverServerPort;
    #   gamemode = "survival";
    #   difficulty = "peaceful";
    #   motd = "Forever Minecraft Server";
    #   "online-mode" = false;
    #   level-name = "world";
    #   level-seed = "-1487282512956129422";
    #   max-players = 20;
    #   white-list = false;
    #   enable-command-block = true;
    #   function-permission-level = 4;
    #   op-permission-level = 4;
    #   spawn-protection = 0;
    #   view-distance = 12;
    # };

    ourworld = {
      server-ip = "127.0.0.1";
      server-port = ourworldServerPort;
      gamemode = "survival";
      difficulty = "normal";
      motd = "Our World Minecraft Server";
      "online-mode" = false;
      level-name = "world";
      level-seed = "100000459812896461";
      max-players = 20;
      white-list = false;
      enable-command-block = true;
      function-permission-level = 4;
      op-permission-level = 4;
      spawn-protection = 0;
      view-distance = 12;
      pvp = false;
    };
  };

  hostFor = name: "${name}.${cfg.hostDomain}";

  velocityConfig = {
    config-version = "2.7";
    bind = "0.0.0.0:${toString publicPort}";
    motd = "Masood's Minecraft Server";
    show-max-players = 20;
    online-mode = false;
    force-key-authentication = false;
    player-info-forwarding-mode = "NONE";
    announce-forge = false;
    kick-existing-players = false;
    ping-passthrough = "DISABLED";
    enable-player-address-logging = true;

    servers = {
      # awesome = "127.0.0.1:${toString awesomeServerPort}";
      # forever = "127.0.0.1:${toString foreverServerPort}";
      ourworld = "127.0.0.1:${toString ourworldServerPort}";
      # try = ["awesome"];
      try = ["ourworld"];
    };

    forced-hosts = {
      # ${hostFor "awesome"} = ["awesome"];
      # ${hostFor "forever"} = ["forever"];
      ${hostFor "ourworld"} = ["ourworld"];
    };
  };

  permSvc = systemdHelpers.mkPermissionService {
    name = "minecraft";
    inherit dataDir;
    user = "minecraft";
    group = "minecraft";
    mode = "0770";
    mainServices = serviceNames;
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-minecraft";
    };
  };
in {
  imports = [
    inputs.nix-minecraft.nixosModules.minecraft-servers
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.hostName == "heartbeat";
        message = "homelab.services.minecraft is heartbeat-only; enable it only on the heartbeat machine.";
      }
    ];

    homelab = {
      zfs = {
        datasets = {
          minecraft = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = dataDir;

            requiredBy = map (name: "${name}.service") serviceNames;

            restic = {
              enable = true;
            };
          };
        };
      };
    };

    services = {
      minecraft-servers = {
        enable = true;
        eula = true;
        inherit dataDir;
        openFirewall = false;
        managementSystem = {
          tmux = {
            enable = false;
          };

          systemd-socket = {
            enable = true;
          };
        };

        servers = {
          velocity = {
            enable = true;
            package = minecraftPackages.velocityServers.velocity;
            jvmOpts = "-Xms512M -Xmx512M";
            stopCommand = "end";

            files = {
              "velocity.toml" = {
                value = velocityConfig;
                format = pkgs.formats.toml {};
              };
            };
          };

          #   awesome = {
          #     enable = true;
          #     package = minecraftPackages.fabricServers."fabric-1_21_10";
          #     jvmOpts = "-Xms4G -Xmx4G";
          #     serverProperties = serverProperties.awesome;
          #   };

          #   forever = {
          #     enable = true;
          #     package = minecraftPackages.fabricServers."fabric-1_20_1";
          #     jvmOpts = "-Xms4G -Xmx4G";
          #     serverProperties = serverProperties.forever;

          #     symlinks = {
          #       mods = pkgs.linkFarmFromDrvs "forever-mods" (
          #         builtins.attrValues (import ./forever-server-mods.nix {inherit pkgs;})
          #       );
          #     };
          #   };

          ourworld = {
            enable = true;
            package = minecraftPackages.fabricServers."fabric-1_21_11";
            jvmOpts = "-Xms2G -Xmx8G";
            serverProperties = serverProperties.ourworld;

            symlinks = {
              mods = pkgs.linkFarmFromDrvs "ourworld-mods" (
                builtins.attrValues (import ./ourworld-server-mods.nix {inherit pkgs;})
              );
            };
          };
        };
      };
    };

    users = {
      users = {
        minecraft = {
          uid = 3014;
        };
      };

      groups = {
        minecraft = {
          gid = 3014;
        };
      };
    };

    systemd = lib.mkMerge [
      permSvc.systemd
      {
        services = {
          # systemd applies WorkingDirectory before ExecStartPre, so create the
          # nix-minecraft per-server directories in the ordered permission unit.
          minecraft-permissions = {
            serviceConfig = {
              ExecStart = lib.mkForce ''
                ${pkgs.coreutils}/bin/install -d -m 0770 -o minecraft -g minecraft ${dataDir} ${lib.concatStringsSep " " serverDataDirs}
              '';
            };
          };

          minecraft-server-velocity = {
            after = [
              # "minecraft-server-awesome.service"
              # "minecraft-server-forever.service"
              "minecraft-server-ourworld.service"
            ];
            wants = [
              # "minecraft-server-awesome.service"
              # "minecraft-server-forever.service"
              "minecraft-server-ourworld.service"
            ];
          };
        };
      }
    ];

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [dataDir];
    };

    networking = {
      firewall = lib.mkIf cfg.openFirewall {
        allowedTCPPorts = [
          publicPort
        ];
      };
    };
  };
}
