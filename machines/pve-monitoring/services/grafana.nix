{
  services = {
    grafana = {
      enable = true;
      openFirewall = true;

      settings = {
        analytics.reporting_enabled = false;

        server = {
          http_addr = "0.0.0.0";
          enforce_domain = true;
          enable_gzip = true;
          domain = "grafana.mantannest.com";
        };
      };
    };
  };
}
