# Options — Questarr video game manager (*arr-style, Podman container).
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        questarr = {
          enable = lib.mkEnableOption "Questarr video game manager.";

          image = lib.mkOption {
            type = lib.types.str;
            # renovate: datasource=docker depName=ghcr.io/doezer/questarr
            default = "ghcr.io/doezer/questarr:v1.6.0";
            description = "Questarr container image.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/questarr";
            description = "Directory for Questarr's SQLite database, config, keys, and backups (/app/data in the container).";
          };

          mediaDir = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/tank/media";
            description = ''
              Media root mounted at the same path inside the container. It holds both
              downloads/ and library/, so imports from qBittorrent's questarr category into
              library/games can hardlink, and no Questarr path mappings are needed.
            '';
          };

          gamesDir = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/tank/media/library/games";
            description = "Game library directory Questarr imports into.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8925;
            description = "Port Questarr listens on (loopback only, behind Caddy).";
          };

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "questarr.${config.networking.domain}";
            description = "Public hostname for Questarr.";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3024;
            description = "UID for the Questarr service user (the container runs as it).";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3024;
            description = "GID for the Questarr service group.";
          };

          environmentFile = lib.mkOption {
            type = lib.types.nullOr lib.types.path;
            default = null;
            description = ''
              Env file with JWT_SECRET, CREDENTIALS_ENCRYPTION_KEY (64 hex chars),
              IGDB_CLIENT_ID and IGDB_CLIENT_SECRET, typically a sops template.
            '';
          };

          zfs = zfsOpts {
            serviceName = "Questarr";
            dataset = "fpool/fast/services/questarr";
            properties = {
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
