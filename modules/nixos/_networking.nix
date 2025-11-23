{config, ...}: let
  networkingCfg = config.homelab.networking;
in {
  networking = {
    inherit (networkingCfg) hostName;
    wireless.enable = networkingCfg.wireless_enable;
    enableIPv6 = false;
  };
}
