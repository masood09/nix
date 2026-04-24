# Options — Vanilla Minecraft Java Edition server (port, memory, seed, ZFS).
# Wraps the upstream NixOS services.minecraft-server module with homelab
# conventions (pinned UID/GID, ZFS dataset, impermanence, permissions service).
{lib, ...}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        minecraft = {
          enable = lib.mkEnableOption "Whether to enable the Minecraft server.";

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
        };
      };
    };
  };
}
