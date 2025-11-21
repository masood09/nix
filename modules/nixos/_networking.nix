{ config,
  ...
}: let
  networkingCfg = config.homelab.networking;
in {
  networking = {
    inherit (networkingCfg) hostName useNetworkd;
    dhcpcd.enable = networkingCfg.dhcpcd_enable;
    interfaces.${networkingCfg.primaryInterface}.useDHCP = true;
    interfaces.${networkingCfg.tailscaleInterface}.useDHCP = false;
    wireless.enable = networkingCfg.wireless_enable;
    enableIPv6 = false;

    extraHosts = networkingCfg.extraHosts;
  };
}
