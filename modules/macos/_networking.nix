{config, ...}: let
  cfg = config.homelab.networking;
in {
  networking = {
    inherit (cfg) hostName;
    computerName = cfg.hostName;
    localHostName = cfg.hostName;
  };
}
