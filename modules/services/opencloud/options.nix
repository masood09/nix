{lib, ...}: {
  options.homelab.services.opencloud = {
    enable = lib.mkEnableOption "Whether to enable Open Cloud.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "cloud.mantannest.com";
    };
  };
}
