{
  config,
  lib,
  ...
}: {
  options.homelab.services.authentik = {
    enable = lib.mkEnableOption "Whether to enable Authentik.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "auth.${config.networking.domain}";
    };
  };
}
