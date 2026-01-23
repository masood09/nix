{
  networking = {
    firewall.checkReversePath = "loose";

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
              address = "10.0.20.2";
              prefixLength = 24;
            }
          ];
        };
      };

      "enp2s0" = {
        useDHCP = false;
      };
    };
  };
}
