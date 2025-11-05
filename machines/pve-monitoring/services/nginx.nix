{
  imports = [
    ./_loki.monitoring.server.mantannest.com.nix
  ];

  services = {
    nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      statusPage = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
