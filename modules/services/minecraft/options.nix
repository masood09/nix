# Options — Minecraft Java Edition server (package, world settings, ZFS).
# Wraps the upstream NixOS services.minecraft-server module with homelab
# conventions (pinned UID/GID, ZFS dataset, impermanence, permissions service).
{
  inputs,
  lib,
  pkgs,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        minecraft = {
          enable = lib.mkEnableOption "Whether to enable the Minecraft server.";

          package = lib.mkOption {
            type = lib.types.package;
            default = inputs.nix-minecraft.legacyPackages.${pkgs.system}.fabricServers."fabric-1_21_10";
            description = "Minecraft server package to run, such as vanilla or Fabric.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/minecraft";
            description = "Directory for Minecraft server persistent data.";
          };

          userId = lib.mkOption {
            default = 3014;
            type = lib.types.ints.u16;
            description = "UID for the Minecraft service user.";
          };

          groupId = lib.mkOption {
            default = 3014;
            type = lib.types.ints.u16;
            description = "GID for the Minecraft service group.";
          };

          port = lib.mkOption {
            default = 25565;
            type = lib.types.port;
            description = "Port for the Minecraft server.";
          };

          memory = lib.mkOption {
            default = "4G";
            type = lib.types.str;
            description = "Memory allocation for the Minecraft JVM (used for both -Xms and -Xmx).";
          };

          seed = lib.mkOption {
            default = "";
            type = lib.types.str;
            # Only applied on initial world generation. Once level.dat exists,
            # Minecraft reads the seed from there and ignores server.properties.
            description = "World seed written to server.properties. Only takes effect when generating a new world; ignored once level.dat exists. Empty string means random.";
          };

          worldName = lib.mkOption {
            default = "world";
            type = lib.types.str;
            description = "World directory name written to server.properties as level-name. Changing it points the server at a different world directory; it does not rename existing world data.";
          };

          motd = lib.mkOption {
            default = "ManTanNest Minecraft Server";
            type = lib.types.str;
            description = "Message of the day shown in the server list.";
          };

          gamemode = lib.mkOption {
            default = "survival";
            type = lib.types.enum ["survival" "creative" "adventure" "spectator"];
            description = "Default game mode for new players.";
          };

          difficulty = lib.mkOption {
            default = "normal";
            type = lib.types.enum ["peaceful" "easy" "normal" "hard"];
            description = "Server difficulty level.";
          };

          maxPlayers = lib.mkOption {
            default = 20;
            type = lib.types.ints.positive;
            description = "Maximum number of concurrent players.";
          };

          onlineMode = lib.mkOption {
            default = true;
            type = lib.types.bool;
            description = "Whether to require Mojang account authentication for connecting clients.";
          };

          operators = lib.mkOption {
            default = {};
            type = lib.types.attrsOf lib.types.str;
            description = "Minecraft operators written to ops.json as a mapping from player name to UUID.";
          };

          operatorPermissionLevel = lib.mkOption {
            default = 4;
            type = lib.types.ints.between 1 4;
            description = "Permission level assigned to declared Minecraft operators.";
          };

          functionPermissionLevel = lib.mkOption {
            default = 4;
            type = lib.types.ints.between 1 4;
            description = "Permission level used by Minecraft functions.";
          };

          enableCommandBlocks = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Whether command blocks are enabled on the server.";
          };

          spawnMonsters = lib.mkOption {
            default = true;
            type = lib.types.bool;
            description = "Whether hostile mobs are allowed to spawn. Passive mobs still follow the upstream server rules.";
          };

          spawnProtection = lib.mkOption {
            default = 16;
            type = lib.types.ints.unsigned;
            description = "Spawn protection radius in blocks. Set to 0 to disable spawn protection.";
          };

          viewDistance = lib.mkOption {
            default = 10;
            type = lib.types.ints.positive;
            description = "Server view distance in chunks.";
          };

          openFirewall = lib.mkOption {
            default = false;
            type = lib.types.bool;
            description = "Whether to open the Minecraft server port in the firewall.";
          };

          zfs = zfsOpts {
            serviceName = "Minecraft";
            dataset = "dpool/tank/services/minecraft";
            properties = {
              recordsize = "128K";
              redundant_metadata = "most";
            };
          };

          minecraft2 = {
            enable = lib.mkEnableOption "Whether to enable the second Minecraft server.";

            package = lib.mkOption {
              type = lib.types.package;
              default = inputs.nix-minecraft.legacyPackages.${pkgs.system}.fabricServers."fabric-1_20_1";
              description = "Minecraft server package to run for the second instance.";
            };

            dataDir = lib.mkOption {
              type = lib.types.path;
              default = "/var/lib/minecraft2";
              description = "Directory for the second Minecraft server's persistent data.";
            };

            user = lib.mkOption {
              type = lib.types.str;
              default = "minecraft2";
              description = "System user that runs the second Minecraft server.";
            };

            group = lib.mkOption {
              type = lib.types.str;
              default = "minecraft2";
              description = "System group that owns the second Minecraft server data.";
            };

            userId = lib.mkOption {
              type = lib.types.ints.u16;
              description = "UID for the second Minecraft service user.";
            };

            groupId = lib.mkOption {
              type = lib.types.ints.u16;
              description = "GID for the second Minecraft service group.";
            };

            port = lib.mkOption {
              type = lib.types.port;
              default = 25566;
              description = "Port for the second Minecraft server.";
            };

            memory = lib.mkOption {
              default = "4G";
              type = lib.types.str;
              description = "Memory allocation for the second Minecraft JVM (used for both -Xms and -Xmx).";
            };

            seed = lib.mkOption {
              default = "";
              type = lib.types.str;
              description = "World seed written to server.properties. Only takes effect when generating a new world; ignored once level.dat exists. Empty string means random.";
            };

            worldName = lib.mkOption {
              default = "world";
              type = lib.types.str;
              description = "World directory name written to server.properties as level-name.";
            };

            motd = lib.mkOption {
              default = "Minecraft Server";
              type = lib.types.str;
              description = "Message of the day shown in the server list.";
            };

            gamemode = lib.mkOption {
              default = "survival";
              type = lib.types.enum ["survival" "creative" "adventure" "spectator"];
              description = "Default game mode for new players.";
            };

            difficulty = lib.mkOption {
              default = "normal";
              type = lib.types.enum ["peaceful" "easy" "normal" "hard"];
              description = "Server difficulty level.";
            };

            maxPlayers = lib.mkOption {
              default = 20;
              type = lib.types.ints.positive;
              description = "Maximum number of concurrent players.";
            };

            onlineMode = lib.mkOption {
              default = true;
              type = lib.types.bool;
              description = "Whether to require Mojang account authentication for connecting clients.";
            };

            operators = lib.mkOption {
              default = {};
              type = lib.types.attrsOf lib.types.str;
              description = "Minecraft operators written to ops.json as a mapping from player name to UUID.";
            };

            operatorPermissionLevel = lib.mkOption {
              default = 4;
              type = lib.types.ints.between 1 4;
              description = "Permission level assigned to declared Minecraft operators.";
            };

            functionPermissionLevel = lib.mkOption {
              default = 4;
              type = lib.types.ints.between 1 4;
              description = "Permission level used by Minecraft functions.";
            };

            enableCommandBlocks = lib.mkOption {
              default = false;
              type = lib.types.bool;
              description = "Whether command blocks are enabled on the server.";
            };

            spawnMonsters = lib.mkOption {
              default = true;
              type = lib.types.bool;
              description = "Whether hostile mobs are allowed to spawn.";
            };

            spawnProtection = lib.mkOption {
              default = 16;
              type = lib.types.ints.unsigned;
              description = "Spawn protection radius in blocks. Set to 0 to disable spawn protection.";
            };

            viewDistance = lib.mkOption {
              default = 10;
              type = lib.types.ints.positive;
              description = "Server view distance in chunks.";
            };

            openFirewall = lib.mkOption {
              default = false;
              type = lib.types.bool;
              description = "Whether to open the second Minecraft server port in the firewall.";
            };

            zfs = zfsOpts {
              serviceName = "Minecraft 2";
              dataset = "dpool/tank/services/minecraft2";
              properties = {
                recordsize = "128K";
                redundant_metadata = "most";
              };
            };
          };
        };
      };
    };
  };
}
