# Machine networking — static IPs on dual NICs, loose reverse-path for Tailscale.
{
  networking = {
    # Loose reverse-path filtering required for Tailscale
    firewall = {
      checkReversePath = "loose";

      # NFS server for the ixian games-library export (services.nfs.server
      # in _config.nix). That module opens no firewall of its own; NFSv4
      # clients only use TCP 2049 — no rpcbind/mountd/statd ports. Which
      # clients may connect is enforced by the export line, not here.
      allowedTCPPorts = [2049];
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
      "eno1" = {
        useDHCP = false;
      };

      "eno2" = {
        useDHCP = false;

        ipv4 = {
          addresses = [
            {
              address = "10.0.1.11";
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
