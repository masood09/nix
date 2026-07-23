# Homelab options — monitoring server (Uptime Kuma).
{
  config = {
    homelab = {
      purpose = "Monitoring & Service Health (Uptime Kuma)";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      hardware = {
        isVM = true;
      };

      networking = {
        hostName = "watchfulsystem";
      };

      programs = {
        fastfetch = {
          zpools = ["rpool"];
        };
      };

      services = {
        acme = {
          zfs = {
            enable = true;
          };
        };

        backup = {
          enable = true;

          # No services are stopped. uptime-kuma keeps its SQLite database in
          # its dataDir, which is the uptime-kuma dataset — so one atomic
          # snapshot captures the db and its journal together, and SQLite
          # recovers on open exactly as it would after a power cut. Stopping it
          # only created a monitoring blind spot during the backup window.
          serviceUnits = [];
        };

        caddy = {
          enable = true;
        };

        # External black-box probing from the watcher host — reachability, HTTP
        # status, latency, and TLS cert expiry for the public vhosts, plus DNS
        # resolver health. Mirrors the endpoints tracked in uptime-kuma, but
        # feeds the central Prometheus so it can join dashboards and alerting.
        blackbox-exporter = {
          enable = true;

          httpTargets = [
            "https://auth.mantannest.com/-/health/live/"
            "https://grafana.mantannest.com/api/health"
            "https://headscale.mantannest.com/health"
            "https://headscale.mantannest.com/admin/healthz"
            "https://photos.mantannest.com/api/server/ping"
            "https://ittools.mantannest.com"
            "https://jobscraper.mantannest.com/health"
            "https://keep.mantannest.com/api/health"
            "https://loki.mantannest.com/ready"
            "https://chat.mantannest.com/-/health"
            "https://mas.chat.mantannest.com/-/health"
            "https://cloud.mantannest.com/-/health"
            "https://collabora.cloud.mantannest.com/hosting/discovery"
            "https://prometheus.mantannest.com/-/healthy"
            "https://passwords.mantannest.com"
          ];

          dnsTargets = [
            "100.64.0.17:53"
            "100.64.0.22:53"
          ];
        };

        tailscale = {
          enable = true;

          zfs = {
            enable = true;
          };
        };

        uptime-kuma = {
          enable = true;

          zfs = {
            enable = true;
          };
        };
      };
    };
  };
}
