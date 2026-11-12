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
    };
  };
}
