# Minecraft — Vanilla Java Edition server with ZFS-backed world storage.
# Delegates to the upstream NixOS services.minecraft-server module for
# process management and EULA handling. We pin UID/GID for registry
# consistency and layer on ZFS, impermanence, and permission-fix service.
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
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
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

    # Upstream NixOS module handles systemd unit, user creation, and EULA.
    # declarative = true means server.properties is overwritten from Nix on
    # every activation — manual edits on disk will not persist.
    services = {
      minecraft-server = {
        enable = true;
        eula = true;
        declarative = true;
        inherit (cfg) dataDir;

        jvmOpts = "-Xms${cfg.memory} -Xmx${cfg.memory}";

        serverProperties = {
          server-port = cfg.port;
          inherit (cfg) gamemode difficulty motd;
          # level-seed is only consulted during initial world generation.
          # Once level.dat exists the seed is stored there; this property
          # is effectively a no-op until the world directory is deleted.
          level-seed = cfg.seed;
          max-players = cfg.maxPlayers;
          white-list = false;
          enable-command-block = false;
          spawn-protection = 16;
          view-distance = 10;
        };
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

    inherit (permSvc) systemd;

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
  };
}
