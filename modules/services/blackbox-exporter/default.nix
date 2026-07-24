# blackbox exporter — black-box probing of endpoints from an outside vantage
# point (as opposed to the white-box, in-process metrics every other exporter
# emits). Answers "can this actually be reached, and is it serving correctly?"
# end-to-end: DNS -> TCP -> TLS -> HTTP. The http_2xx module also yields
# probe_ssl_earliest_cert_expiry, giving a per-vhost certificate-expiry
# timeseries — the early warning a silently-failed ACME renewal otherwise lacks.
# Intended to run on the dedicated watcher host. No secrets: probes are
# unauthenticated and the module config only names probe types.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab.services.blackbox-exporter;

  blackboxConfig = (pkgs.formats.yaml {}).generate "blackbox-exporter.yml" {
    modules = {
      http_2xx = {
        prober = "http";
        timeout = "10s";
        http = {
          method = "GET";
          fail_if_not_ssl = true;
          preferred_ip_protocol = "ip4";
          ip_protocol_fallback = false;
        };
      };

      dns_a = {
        prober = "dns";
        timeout = "5s";
        dns = {
          query_name = cfg.dnsQueryName;
          query_type = "A";
          preferred_ip_protocol = "ip4";
        };
      };
    };
  };
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    services = {
      prometheus = {
        exporters = {
          blackbox = {
            enable = true;
            listenAddress = "127.0.0.1";
            configFile = blackboxConfig;
          };
        };
      };
    };
  };
}
