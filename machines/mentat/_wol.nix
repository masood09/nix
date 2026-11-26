# Wake-on-LAN for ixian — `systemctl start wake-ixian` wakes it from suspend.
#
# ixian suspends itself when idle (machines/ixian/_suspend.nix) and sits on
# VLAN 30 (Home), while mentat is on VLAN 20 (servers). A magic packet is a
# broadcast, which the gateway doesn't route between VLANs, so mentat gets a
# tagged VLAN 30 interface with no address (wol30, _networking.nix) and sends
# the packet there as a raw Ethernet frame. _wake-ixian.py has the details.
#
# mentat sends it because LiteLLM, which notices that a request needs ixian,
# runs here.
{
  config,
  pkgs,
  ...
}: let
  wakeIxian =
    pkgs.writers.writePython3 "wake-ixian" {
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./_wake-ixian.py);
in {
  config = {
    systemd = {
      services = {
        wake-ixian = {
          description = "Wake ixian with a Wake-on-LAN magic packet";
          after = ["network-addresses-wol30.service"];
          wants = ["network-addresses-wol30.service"];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${wakeIxian} wol30";
            LoadCredential = ["ixian-mac:${config.sops.secrets."wol/ixian-mac".path}"];

            # A raw frame needs CAP_NET_RAW and nothing else.
            DynamicUser = true;
            AmbientCapabilities = ["CAP_NET_RAW"];
            CapabilityBoundingSet = ["CAP_NET_RAW"];
            RestrictAddressFamilies = ["AF_PACKET"];
            NoNewPrivileges = true;
            PrivateDevices = true;
            ProtectHome = true;
            ProtectSystem = "strict";
          };
        };
      };
    };
  };
}
