{
  config,
  lib,
  ...
}: let
  headscaleCfg = config.homelab.services.headscale;
in {
  config = lib.mkIf headscaleCfg.enable {
    services = {
      headscale = {
        settings = {
          dns = {
            override_local_dns = false;

            base_domain = "dns.${headscaleCfg.webDomain}";

            extra_records = [
              {
                name = "database.mantannest.com";
                type = "A";
                value = "100.64.0.23";
              }
              {
                name = "passwords.mantannest.com";
                type = "A";
                value = "100.64.0.23";
              }
              {
                name = "photos.mantannest.com";
                type = "A";
                value = "100.64.0.23";
              }
              {
                name = "grafana.mantannest.com";
                type = "A";
                value = "100.64.0.7";
              }
              {
                name = "keep.mantannest.com";
                type = "A";
                value = "100.64.0.13";
              }
              {
                name = "homeassistant.mantannest.com";
                type = "A";
                value = "100.64.0.13";
              }
              {
                name = "loki.monitoring.server.mantannest.com";
                type = "A";
                value = "100.64.0.7";
              }
              {
                name = "prometheus.monitoring.server.mantannest.com";
                type = "A";
                value = "100.64.0.7";
              }
            ];
          };
        };
      };
    };
  };
}
