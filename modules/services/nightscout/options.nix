{
  config,
  lib,
  ...
}: {
  options.homelab.services = {
    nightscout = {
      enable = lib.mkEnableOption "Whether to enable Nightscout.";

      webDomain = lib.mkOption {
        type = lib.types.str;
        default = "nightscout.${config.networking.domain}";
      };

      listenAddress = lib.mkOption {
        default = "127.0.0.1";
        type = lib.types.str;
      };

      port = lib.mkOption {
        default = 8914;
        type = lib.types.port;
      };

      openFirewall = lib.mkOption {
        default = false;
        type = lib.types.bool;
      };

      userId = lib.mkOption {
        default = 3013;
        type = lib.types.ints.u16;
      };

      groupId = lib.mkOption {
        default = 3013;
        type = lib.types.ints.u16;
      };
    };
  };
}
