{
  networking = {
    firewall.checkReversePath = "loose";

    useDHCP = false;

    defaultGateway = {
      address = "10.0.20.1";
      interface = "ens18";
    };

    nameservers = [
      "10.0.20.1"
    ];

    interfaces = {
      "ens18" = {
        useDHCP = false;

        ipv4 = {
          addresses = [
            {
              address = "10.0.20.253";
              prefixLength = 24;
            }
          ];
        };
      };

      "ens19" = {
        useDHCP = false;

        ipv4 = {
          addresses = [
            {
              address = "10.0.1.252";
              prefixLength = 24;
            }
          ];
        };
      };
    };
  };
}
