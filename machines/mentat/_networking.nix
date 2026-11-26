# Machine networking — static IP on VLAN 20, loose reverse-path for Tailscale.
{
  networking = {
    # Loose reverse-path filtering required for Tailscale
    firewall = {
      checkReversePath = "loose";
    };

    useDHCP = false;

    defaultGateway = {
      address = "10.0.20.1";
      interface = "enp1s0";
    };

    nameservers = [
      "10.0.20.1"
    ];

    # VLAN 30 (Home, ixian's network) arrives tagged on the switch port, only
    # so wake-ixian can put a Wake-on-LAN frame on it (_wol.nix). It gets no
    # address, and IPv6 is off on this host, so mentat has no IP presence on
    # that VLAN: it can't route between the VLANs, and Home can't reach it.
    vlans = {
      wol30 = {
        id = 30;
        interface = "enp1s0";
      };
    };

    interfaces = {
      "enp1s0" = {
        useDHCP = false;

        ipv4 = {
          addresses = [
            {
              address = "10.0.20.4";
              prefixLength = 24;
            }
          ];
        };
      };

      wol30 = {
        useDHCP = false;
      };
    };
  };
}
