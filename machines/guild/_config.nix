# Homelab options — CI/CD and binary-cache server (services to come) and a
# future Hermes agent host. Minimal for now: fleet baseline only.
{
  config = {
    homelab = {
      role = "server";
      purpose = "CI/CD & Binary Cache Server";
      isRootZFS = true;
      isEncryptedRoot = true;
      impermanence = true;

      networking = {
        hostName = "guild";
      };

      programs = {
        fastfetch = {
          zpools = [
            "rpool"
            "cipool"
            "agentpool"
          ];
        };
      };

      services = {
        # Ships journald logs to Loki and node metrics to Prometheus on
        # heartbeat via the shared alloy/.env endpoints.
        alloy = {
          enable = true;
        };

        # Disabled: no state yet. Enable (with restic secrets) once the cache
        # or Hermes hold data worth keeping.
        backup = {
          enable = false;
        };

        # Bare-metal host with three SSDs: per-disk SMART health. No BMC, so
        # no IPMI exporter here.
        smartctl-exporter = {
          enable = true;
        };

        tailscale = {
          enable = true;
        };
      };
    };
  };
}
