{
  services = {
    prometheus = {
      enable = true;
    };
  };

  networking.firewall.allowedTCPPorts = [ 9090 ];
}
