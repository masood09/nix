# macOS networking — sets hostname/computerName/localHostName.
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab.networking;
in {
  config = {
    networking = {
      inherit (cfg) hostName;
      computerName = cfg.hostName;
      localHostName = cfg.hostName;
    };
  };
}
