{lib, ...}: {
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Whether to enable Immich.";

    mediaLocation = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/immich";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "photos.mantannest.com";
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
  };
}
