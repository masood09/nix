{
  services = {
    prometheus = {
      enable = true;
      globalConfig.scrape_interval = "10s";

      scrapeConfigs = [
        {
          job_name = "node";
          static_configs = [
            {
              targets = [
                "oci-auth-server.dns.headscale.mantannest.com:9100"
                "oci-vpn-server.dns.headscale.mantannest.com:9100"
                "pve-server-1.dns.headscale.mantannest.com:9100"
                "pve-server-monitoring.dns.headscale.mantannest.com:9100"
              ];
            }
          ];
        }
        {
          job_name = "authentik";
          static_configs = [
            {
              targets = [
                "oci-auth-server.dns.headscale.mantannest.com:9300"
                "oci-auth-server.dns.headscale.mantannest.com:9301"
              ];
            }
          ];
        }
        {
          job_name = "postgresql";
          static_configs = [
            {
              targets = [
                "oci-auth-server.dns.headscale.mantannest.com:9187"
                "pve-server-1.dns.headscale.mantannest.com:9187"
              ];
            }
          ];
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [9090];
}
