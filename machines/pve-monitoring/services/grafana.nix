{ config, ... }: {
  services = {
    grafana = {
      enable = true;
      openFirewall = true;

      provision = {
        enable = true;

        datasources.settings.datasources = [
          {
            name = "Loki";
            type = "loki";
            access = "proxy";
            url = "http://127.0.0.1:3100";
          }
        ];
      };

      settings = {
        analytics.reporting_enabled = false;


        server = {
          enforce_domain = true;
          enable_gzip = true;
          domain = "grafana.mantannest.com";
        };
      };
    };
  };
}
