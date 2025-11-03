{
  services = {
    alloy = {
      enable = true;

      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:12345"
        "--disable-reporting"
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [12345];

  environment.etc."alloy/config.alloy".source = ../files/alloy/config.alloy;
}
