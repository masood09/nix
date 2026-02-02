{
  config,
  lib,
  ...
}: {
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Whether to enable Immich.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/immich";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "photos.${config.networking.domain}";
    };

    userId = lib.mkOption {
      default = 3001;
      type = lib.types.ints.u16;
      description = "User ID of Immich user";
    };

    groupId = lib.mkOption {
      default = 3001;
      type = lib.types.ints.u16;
      description = "Group ID of Immich group";
    };

    zfs = {
      enable = lib.mkEnableOption "Store Immich dataDir on a ZFS dataset.";

      restic = {
        enable = lib.mkEnableOption "Enable restic backup";
      };

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/immich";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          recordsize = "1M";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };
}
