# Options — Uptime Kuma service monitor (domain, port, ZFS).
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
        uptime-kuma = {
          enable = lib.mkEnableOption "Whether to enable Uptime Kuma.";

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/uptime-kuma/";
            description = "Directory for Uptime Kuma data storage.";
          };

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "uptime.${config.networking.domain}";
            description = "Domain name for the Uptime Kuma web interface.";
          };

          userId = lib.mkOption {
            default = 3002;
            type = lib.types.ints.u16;
            description = "User ID of Uptime Kuma user";
          };

          groupId = lib.mkOption {
            default = 3002;
            type = lib.types.ints.u16;
            description = "Group ID of Uptime Kuma group";
          };

          zfs = zfsOpts {
            serviceName = "Uptime Kuma";
            dataset = "rpool/root/var/lib/uptime-kuma";
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
