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
          home = cfg.dataDir;
          linger = true;

          subUidRanges = [
            {
              startUid = 100000;
              count = 65536;
            }
          ];

          subGidRanges = [
            {
              startGid = 100000;
              count = 65536;
            }
          ];
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
