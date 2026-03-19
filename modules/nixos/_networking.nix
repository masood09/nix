# Networking — hostname, domain, firewall, and optional WiFi via NetworkManager.
# Generates a deterministic hostId from the hostname (required by ZFS).
{
  config,
  lib,
  ...
}: let
  networkingCfg = config.homelab.networking;
in {
  options.homelab.networking = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "mantannest.com";
    };

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
      inherit (networkingCfg) hostName domain;

      # WiFi machines (desktops/laptops) use NetworkManager
      networkmanager.enable = networkingCfg.wireless_enable;
      enableIPv6 = false;

      # ZFS requires a unique 8-char hostId; derive it from hostname
      hostId = builtins.substring 0 8 (
        builtins.hashString "sha256" config.networking.hostName
      );

      firewall.enable = true;
    };
  };
}
