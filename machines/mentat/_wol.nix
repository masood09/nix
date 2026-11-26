# Wake-on-LAN for ixian, and the proxy that wakes it for LiteLLM.
#
# ixian suspends itself when idle (machines/ixian/_suspend.nix) and sits on
# VLAN 30 (Home), while mentat is on VLAN 20 (servers). A magic packet is a
# broadcast, which the gateway doesn't route between VLANs, so mentat gets a
# tagged VLAN 30 interface with no address (wol30, _networking.nix) and sends
# the packet there as a raw Ethernet frame. _wake-ixian.py has the details.
#
#   * `systemctl start wake-ixian` wakes ixian by hand.
#   * wake-proxy (_wake-proxy.py) sits between LiteLLM and model-router on
#     ixian: when ixian doesn't answer, it wakes it, holds the request, and
#     forwards it once model-router is back. LiteLLM's ixian backend points at
#     it (_config.nix). There is deliberately no fallback to another model.
{
  config,
  lib,
  pkgs,
  ...
}: let
  wakeIxian =
    pkgs.writers.writePython3 "wake-ixian" {
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./_wake-ixian.py);

  wakeProxy =
    pkgs.writers.writePython3 "wake-proxy" {
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./_wake-proxy.py);

  macCredential = "ixian-mac:${config.sops.secrets."wol/ixian-mac".path}";
  wol30 = ["network-addresses-wol30.service"];
in {
  options = {
    homelab = {
      wakeProxy = {
        port = lib.mkOption {
          type = lib.types.port;
          default = 8926;
          description = "Loopback port of the ixian wake proxy (docs/service-registry.org).";
        };
      };
    };
  };

  config = {
    systemd = {
      services = {
        wake-ixian = {
          description = "Wake ixian with a Wake-on-LAN magic packet";
          after = wol30;
          wants = wol30;

          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${wakeIxian} wol30";
            LoadCredential = [macCredential];

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

        wake-proxy = {
          description = "Proxy LiteLLM to ixian, waking ixian if it sleeps";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"] ++ wol30;
          wants = ["network-online.target"] ++ wol30;

          serviceConfig = {
            # It runs wake-ixian's script itself rather than starting the
            # unit, so it needs no systemd rights: the ambient CAP_NET_RAW and
            # the MAC credential pass to the child.
            ExecStart =
              lib.escapeShellArgs [
                (toString wakeProxy)
                "--listen-port"
                (toString config.homelab.wakeProxy.port)
                "--upstream-host"
                "ixian.dns.headscale.${config.networking.domain}"
                "--upstream-port"
                "8922"
              ]
              # Answered without waking ixian when LiteLLM (every 5 min) or a
              # client asks for the model list while ixian sleeps.
              + " "
              + lib.escapeShellArgs (lib.concatMap (m: ["--model" m]) config.homelab.services.litellm.backends.ixian.models)
              + " "
              + lib.escapeShellArgs [
                (toString wakeIxian)
                "wol30"
              ];
            LoadCredential = [macCredential];
            Restart = "always";
            RestartSec = 5;

            DynamicUser = true;
            AmbientCapabilities = ["CAP_NET_RAW"];
            CapabilityBoundingSet = ["CAP_NET_RAW"];
            RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX" "AF_PACKET"];
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
