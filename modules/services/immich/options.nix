{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Whether to enable Immich.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/immich";
      description = "Directory for Immich data storage.";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "photos.${config.networking.domain}";
      description = "Domain name for the Immich web interface.";
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

    zfs = zfsOpts {
      serviceName = "Immich";
      dataset = "dpool/tank/services/immich";
      properties = {
        compression = "lz4";
        recordsize = "1M";
      };
      withRestic = true;
    };
  };
}
