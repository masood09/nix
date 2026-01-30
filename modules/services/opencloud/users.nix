{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.opencloud;
  podmanEnabled = homelabCfg.services.podman.enable;
in {
  config = lib.mkIf (cfg.enable && podmanEnabled) {
    users = {
      users = {
        opencloud = {
          isSystemUser = true;
          group = "opencloud";
          uid = cfg.userId;
        };
      };

      groups = {
        opencloud = {
          gid = cfg.groupId;
        };
      };
    };
  };
}
