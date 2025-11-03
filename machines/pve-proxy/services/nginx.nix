{
  services = {
    nginx = {
      enable = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;
      statusPage = true;
    };

    prometheus.exporters.nginx = {
      enable = true;
      openFirewall = true;
      scrapeUri = "http://localhost/nginx_status";
    };
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
