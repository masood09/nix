{
  config,
  lib,
  ...
}: let
  networkingCfg = config.homelab.networking;
in {
  options.homelab.networking = {
    hostName = lib.mkOption {
      type = lib.types.str;
      description = ''
        The hostname of the machine.
      '';
    };

    wireless_enable = lib.mkOption {
      default = false;
      type = lib.types.bool;
    };
  };

  config = {
    networking = {
      inherit (networkingCfg) hostName;
      wireless.enable = networkingCfg.wireless_enable;
      enableIPv6 = false;
      hostId = builtins.substring 0 8 (
        builtins.hashString "sha256" config.networking.hostName
      );

      firewall.enable = true;
    };
  };
}
