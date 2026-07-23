# Options — Prometheus blackbox exporter (external black-box probing).
{lib, ...}: {
  options = {
    homelab = {
      services = {
        blackbox-exporter = {
          enable = lib.mkEnableOption "the Prometheus blackbox exporter for external probing (HTTP reachability, TLS cert expiry, DNS resolver health).";

          httpTargets = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["https://grafana.example.com/api/health"];
            description = "HTTPS URLs probed with the http_2xx module: reachability, status class, latency, and TLS certificate expiry.";
          };

          dnsTargets = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["10.0.0.1:53"];
            description = "DNS resolver addresses (host:port) probed with the dns module.";
          };

          dnsQueryName = lib.mkOption {
            type = lib.types.str;
            default = "example.com";
            description = "Name the dns module resolves against each dnsTargets resolver — an external canary for resolver health.";
          };
        };
      };
    };
  };
}
