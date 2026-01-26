{
  networking = {
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
              address = "10.0.20.4";
              prefixLength = 24;
            }
          ];
        };
      };
    };
  };
}
