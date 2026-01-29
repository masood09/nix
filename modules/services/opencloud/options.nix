{lib, ...}: {
  options.homelab.services.opencloud = {
    enable = lib.mkEnableOption "Whether to enable Open Cloud.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "cloud.mantannest.com";
    };

    userId = lib.mkOption {
      default = 3008;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3008;
      type = lib.types.ints.u16;
    };
  };
}
