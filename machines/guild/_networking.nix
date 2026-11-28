# Machine networking — static IP on the 10 GbE port in VLAN 20 (servers).
#
# Only the 10 GbE port (enp1s0f1) is configured on the host, so there is a
# single default route. The onboard port (eno1, VLAN 80) is reserved for the
# Hermes agent, which will get it in a network namespace of its own; until then
# it has no address here.
#
# The initrd brings up both ports for the remote LUKS unlock (port 2222). The
# 10 GbE port gets the static address below: NixOS generates that initrd
# network (40-enp1s0f1) from networking.interfaces. The onboard port is added
# by DHCP as a fallback, since bnx2x needs firmware in the initrd and e1000e
# does not. Declared as a systemd-networkd network (ixian's pattern) so it is
# flushed before stage 2 instead of leaking its lease into the running system.
{
  config = {
    networking = {
      # Loose reverse-path filtering required for Tailscale
      firewall = {
        checkReversePath = "loose";
      };

      useDHCP = false;

      defaultGateway = {
        address = "10.0.20.1";
        interface = "enp1s0f1";
      };

      nameservers = [
        "10.0.20.1"
      ];

      interfaces = {
        "enp1s0f1" = {
          useDHCP = false;

          ipv4 = {
            addresses = [
              {
                address = "10.0.20.5";
                prefixLength = 24;
              }
            ];
          };
        };
      };
    };

    boot = {
      initrd = {
        systemd = {
          network = {
            networks = {
              "20-initrd-onboard" = {
                matchConfig = {
                  Name = "eno1";
                };
                networkConfig = {
                  DHCP = "ipv4";
                };
              };
            };
          };
        };
      };
    };
  };
}
