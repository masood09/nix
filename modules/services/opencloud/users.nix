{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.opencloud;
in {
  config = lib.mkIf cfg.enable {
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
