# Options — Questarr game library manager (domain, port, and media paths).
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        questarr = {
          enable = lib.mkEnableOption "Whether to enable Questarr.";

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "questarr.${config.networking.domain}";
            description = "Domain name for the Questarr web interface.";
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/arr/questarr";
            description = "Persistent Questarr data directory.";
          };

          mediaDir = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/tank/media/library";
            description = "Questarr game library root.";
          };

          downloadsDir = lib.mkOption {
            type = lib.types.path;
            default = "/mnt/tank/media/downloads";
            description = "Questarr downloads root.";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3016;
            description = "UID for the Questarr service user.";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3016;
            description = "GID for the Questarr service group.";
          };

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "0.0.0.0";
            description = "Address for the Questarr host port binding.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8916;
            description = "Host port for Questarr's HTTP service.";
          };
        };
      };
    };
  };
}
