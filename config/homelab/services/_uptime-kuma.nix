{lib, ...}: {
  options.homelab.services.uptime-kuma = {
    enable = lib.mkEnableOption "Whether to enable Uptime Kuma.";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/uptime-kuma/";
    };

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "uptime.mantannest.com";
    };

    userId = lib.mkOption {
      default = 3002;
      type = lib.types.ints.u16;
      description = "User ID of Alloy user";
    };

    groupId = lib.mkOption {
      default = 3002;
      type = lib.types.ints.u16;
      description = "Group ID of Alloy group";
    };
  };
}
