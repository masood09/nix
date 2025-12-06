{config, ...}: let
  networkingCfg = config.homelab.networking;
in {
  networking = {
    inherit (networkingCfg) hostName;
    wireless.enable = networkingCfg.wireless_enable;
    enableIPv6 = false;
    hostId = builtins.substring 0 8 (
      builtins.hashString "sha256" config.networking.hostName
    );

    firewall.enable = true;
  };
}
