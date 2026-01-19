{
  networking = {
    firewall.checkReversePath = "loose";

    useDHCP = false;

    defaultGateway = {
      address = "10.0.20.1";
      interface = "enp1s0f1";
    };

    nameservers = [
      "10.0.20.1"
    ];

    interfaces = {
      "eno1" = {
        useDHCP = false;
      };

      "eno2" = {
        useDHCP = false;

        ipv4 = {
          addresses = [
            {
              address = "10.0.1.14";
              prefixLength = 24;
            }
          ];
        };
      };

      "enp1s0f0" = {
        useDHCP = false;
      };

      "enp1s0f1" = {
        useDHCP = false;

        ipv4 = {
          addresses = [
            {
              address = "10.0.20.3";
              prefixLength = 24;
            }
          ];
        };
      };
    };
  };
}
