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
            override_local_dns = true;

            base_domain = "dns.${headscaleCfg.webDomain}";

            nameservers = {
              global = [
                "100.64.0.13"
              ];
            };

            extra_records_path = config.sops.secrets."headscale-extra-records.json".path;
          };
        };
      };
    };
  };
}
