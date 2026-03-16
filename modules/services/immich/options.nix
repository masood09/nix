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

    zfs = zfsOpts {
      serviceName = "Immich";
      dataset = "dpool/tank/services/immich";
      properties = {
        recordsize = "1M";
      };
      withRestic = true;
    };
  };
}
