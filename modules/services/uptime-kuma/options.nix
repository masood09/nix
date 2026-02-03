{
  config,
  lib,
  ...
}: {
  options.homelab.services.uptime-kuma = {
    enable = lib.mkEnableOption "Whether to enable Uptime Kuma.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/uptime-kuma/";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "uptime.${config.networking.domain}";
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

    zfs = {
      enable = lib.mkEnableOption "Store Uptime Kuma dataDir on a ZFS dataset.";

      restic = {
        enable = lib.mkEnableOption "Enable restic backup";
      };

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "rpool/root/var/lib/uptime-kuma";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          recordsize = "16K";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };
}
