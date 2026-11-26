# Service modules — each sub-directory defines a self-contained service
# with its own homelab.services.<name>.enable option. Services are imported
# unconditionally but only activate when enabled in a machine's _config.nix.
# See docs/service-registry.org for UID/GID/port assignments.
{
  imports = [
    ./actual
    ./alloy
    ./arr
    ./aurral
    ./authentik
    ./babybuddy
    ./backup
    ./blackbox-exporter
    ./blocky
    ./caddy
    ./console-mode
    ./dell-idrac-fan-controller
    ./garage
    ./grafana
    ./headscale
    ./home-assistant
    ./immich
    ./ipmi-exporter
    ./ittools
    ./jobscraper
    ./karakeep
    ./litellm
    ./llama-cpp
    ./loki
    ./mailarchiver
    ./matrix
    ./minecraft
    ./model-router
    ./mongodb
    ./nightscout
    ./open-webui
    ./opencloud
    ./podman
    ./postgresql
    ./prometheus
    ./questarr
    ./searxng
    ./smartctl-exporter
    ./ssh
    ./strata
    ./tailscale
    ./uptime-kuma
    ./vaultwarden
  ];

  services = {
    fstrim = {
      enable = true;
    };
  };
}
