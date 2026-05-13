# Minecraft — Java Edition servers with ZFS-backed world storage.
# The primary instance delegates process management to the upstream NixOS
# services.minecraft-server module. Extra instances mirror the upstream unit
# because that module is single-instance.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.minecraft;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  cfgToString = value:
    if builtins.isBool value
    then lib.boolToString value
    else toString value;
  minecraftServerProperties = serverCfg: {
    server-port = serverCfg.port;
    inherit (serverCfg) gamemode difficulty motd;
    "online-mode" = serverCfg.onlineMode;
    level-name = serverCfg.worldName;
    level-seed = serverCfg.seed;
    max-players = serverCfg.maxPlayers;
    white-list = false;
    enable-command-block = serverCfg.enableCommandBlocks;
    function-permission-level = serverCfg.functionPermissionLevel;
    op-permission-level = serverCfg.operatorPermissionLevel;
    spawn-monsters = serverCfg.spawnMonsters;
    spawn-protection = serverCfg.spawnProtection;
    view-distance = serverCfg.viewDistance;
  };
  mkOpsFile = name: serverCfg:
    pkgs.writeText "${name}-ops.json" (
      builtins.toJSON (
        lib.mapAttrsToList (operatorName: uuid: {
          inherit uuid;
          name = operatorName;
          level = serverCfg.operatorPermissionLevel;
          bypassesPlayerLimit = false;
        })
        serverCfg.operators
      )
    );
  mkServerPropertiesFile = name: serverCfg:
    pkgs.writeText "${name}-server.properties" (
      ''
        # server.properties managed by NixOS configuration
      ''
      + lib.concatStringsSep "\n" (
        lib.mapAttrsToList (propertyName: value: "${propertyName}=${cfgToString value}") (minecraftServerProperties serverCfg)
      )
    );
  eulaFile = builtins.toFile "minecraft-eula.txt" ''
    # eula.txt managed by NixOS Configuration
    eula=true
  '';
  permSvc = systemdHelpers.mkPermissionService {
    name = "minecraft";
    inherit (cfg) dataDir;
    user = "minecraft";
    group = "minecraft";
    mainServices = ["minecraft-server"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-minecraft";
    };
  };
  minecraft2CollisionAssertions = let
    minecraft2Cfg = cfg.minecraft2;
  in
    lib.optionals minecraft2Cfg.enable [
      {
        assertion = minecraft2Cfg.port != cfg.port;
        message = "homelab.services.minecraft.minecraft2.port must not match the primary Minecraft server port.";
      }
      {
        assertion = minecraft2Cfg.dataDir != cfg.dataDir;
        message = "homelab.services.minecraft.minecraft2.dataDir must not match the primary Minecraft dataDir.";
      }
      {
        assertion = minecraft2Cfg.user != "minecraft";
        message = "homelab.services.minecraft.minecraft2.user must not be minecraft; the primary server owns that user.";
      }
      {
        assertion = minecraft2Cfg.group != "minecraft";
        message = "homelab.services.minecraft.minecraft2.group must not be minecraft; the primary server owns that group.";
      }
      {
        assertion = minecraft2Cfg.userId != cfg.userId;
        message = "homelab.services.minecraft.minecraft2.userId must not match the primary Minecraft UID.";
      }
      {
        assertion = minecraft2Cfg.groupId != cfg.groupId;
        message = "homelab.services.minecraft.minecraft2.groupId must not match the primary Minecraft GID.";
      }
      {
        assertion = minecraft2Cfg.zfs.dataset != cfg.zfs.dataset;
        message = "homelab.services.minecraft.minecraft2.zfs.dataset must not match the primary Minecraft dataset.";
      }
    ];
  mkExtraServerConfig = name: serverCfg: let
    serviceName = name;
    socketName = "${serviceName}.socket";
    fifoPath = "/run/${serviceName}.stdin";
    opsFile = mkOpsFile serviceName serverCfg;
    serverPropertiesFile = mkServerPropertiesFile serviceName serverCfg;
    modsDir = pkgs.linkFarmFromDrvs "${serviceName}-mods" (builtins.attrValues serverCfg.mods);
    stopScript = pkgs.writeShellScript "${serviceName}-stop" ''
      echo stop > ${fifoPath}

      while kill -0 "$1" 2> /dev/null; do
        sleep 1s
      done
    '';
    extraPermSvc = systemdHelpers.mkPermissionService {
      name = serviceName;
      inherit (serverCfg) dataDir user group;
      mainServices = [serviceName];
      zfs = {
        inherit (serverCfg.zfs) enable;
        datasetServiceName = "zfs-dataset-${serviceName}";
      };
    };
  in
    lib.mkIf serverCfg.enable {
      homelab = {
        zfs = {
          datasets = {
            ${serviceName} = lib.mkIf serverCfg.zfs.enable {
              inherit (serverCfg.zfs) dataset properties;

              enable = true;
              mountpoint = serverCfg.dataDir;

              requiredBy = [
                "${serviceName}.service"
              ];

              restic = {
                enable = true;
              };
            };
          };
        };
      };

      users = {
        users = {
          ${serverCfg.user} = {
            uid = serverCfg.userId;
            description = "${serviceName} service user";
            home = serverCfg.dataDir;
            createHome = true;
            isSystemUser = true;
            inherit (serverCfg) group;
          };
        };

        groups = {
          ${serverCfg.group} = {
            gid = serverCfg.groupId;
          };
        };
      };

      systemd = lib.mkMerge [
        extraPermSvc.systemd
        {
          sockets = {
            ${serviceName} = {
              bindsTo = ["${serviceName}.service"];
              socketConfig = {
                ListenFIFO = fifoPath;
                SocketMode = "0660";
                SocketUser = serverCfg.user;
                SocketGroup = serverCfg.group;
                RemoveOnStop = true;
                FlushPending = true;
              };
            };
          };

          services = {
            ${serviceName} = {
              description = "${serviceName} service";
              wantedBy = ["multi-user.target"];
              requires = [socketName];
              after = [
                "network.target"
                socketName
              ];

              preStart = ''
                ln -sf ${eulaFile} eula.txt
                ln -sf ${opsFile} ops.json
                cp -f ${serverPropertiesFile} server.properties
                chmod +w server.properties
                if [ -e mods ] && [ ! -L mods ]; then
                  if [ -e mods.pre-nix-managed ]; then
                    echo "Refusing to replace existing mods directory because mods.pre-nix-managed already exists" >&2
                    exit 1
                  fi
                  mv mods mods.pre-nix-managed
                fi
                ln -sfn ${modsDir} mods
                echo "Autogenerated file that signifies that this server configuration is managed declaratively by NixOS" > .declarative
              '';

              serviceConfig = {
                ExecStart = "${serverCfg.package}/bin/minecraft-server -Xms${serverCfg.memory} -Xmx${serverCfg.memory}";
                ExecStop = "${stopScript} $MAINPID";
                Restart = "always";
                User = serverCfg.user;
                WorkingDirectory = serverCfg.dataDir;

                StandardInput = "socket";
                StandardOutput = "journal";
                StandardError = "journal";

                CapabilityBoundingSet = [""];
                DeviceAllow = [""];
                LockPersonality = true;
                PrivateDevices = true;
                PrivateTmp = true;
                PrivateUsers = true;
                ProtectClock = true;
                ProtectControlGroups = true;
                ProtectHome = true;
                ProtectHostname = true;
                ProtectKernelLogs = true;
                ProtectKernelModules = true;
                ProtectKernelTunables = true;
                ProtectProc = "invisible";
                RestrictAddressFamilies = [
                  "AF_INET"
                  "AF_INET6"
                ];
                RestrictNamespaces = true;
                RestrictRealtime = true;
                RestrictSUIDSGID = true;
                SystemCallArchitectures = "native";
                UMask = "0077";
              };
            };
          };
        }
      ];

      environment = persistenceHelpers.mkPersistenceDirs {
        inherit homelabCfg;
        zfsEnable = serverCfg.zfs.enable;
        directories = [serverCfg.dataDir];
      };

      networking = {
        firewall = lib.mkIf serverCfg.openFirewall {
          allowedTCPPorts = [
            serverCfg.port
          ];
        };
      };
    };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable (lib.mkMerge ([
      {
        homelab = {
          zfs = {
            datasets = {
              minecraft = lib.mkIf cfg.zfs.enable {
                inherit (cfg.zfs) dataset properties;

                enable = true;
                mountpoint = cfg.dataDir;

                requiredBy = [
                  "minecraft-server.service"
                ];

                restic = {
                  enable = true;
                };
              };
            };
          };
        };

        assertions = minecraft2CollisionAssertions;

        # Upstream NixOS module handles systemd unit, user creation, and EULA.
        # declarative = true means server.properties is overwritten from Nix on
        # every activation — manual edits on disk will not persist.
        services = {
          minecraft-server = {
            enable = true;
            eula = true;
            declarative = true;
            inherit (cfg) dataDir package;

            jvmOpts = "-Xms${cfg.memory} -Xmx${cfg.memory}";

            serverProperties = minecraftServerProperties cfg;
          };
        };

        # Pin UID/GID for service registry consistency; the upstream module
        # creates the minecraft user/group, we just constrain the numeric IDs.
        users = {
          users = {
            minecraft = {
              uid = cfg.userId;
            };
          };

          groups = {
            minecraft = {
              gid = cfg.groupId;
            };
          };
        };

        systemd = lib.mkMerge [
          permSvc.systemd
          {
            services = {
              minecraft-server = {
                preStart = lib.mkAfter ''
                  ln -sf ${mkOpsFile "minecraft" cfg} ops.json
                '';
              };
            };
          }
        ];

        environment = persistenceHelpers.mkPersistenceDirs {
          inherit homelabCfg;
          zfsEnable = cfg.zfs.enable;
          directories = [cfg.dataDir];
        };

        # Minecraft Java Edition uses TCP only; UDP 25565 is LAN broadcast
        # which is irrelevant for a dedicated headless server.
        networking = {
          firewall = lib.mkIf cfg.openFirewall {
            allowedTCPPorts = [
              cfg.port
            ];
          };
        };
      }
    ]
    ++ [
      (
        mkExtraServerConfig "minecraft2" cfg.minecraft2
      )
    ]));
}
