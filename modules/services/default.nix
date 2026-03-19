# Service modules — each sub-directory defines a self-contained service
# with its own homelab.services.<name>.enable option. Services are imported
# unconditionally but only activate when enabled in a machine's _config.nix.
# See docs/service-registry.org for UID/GID/port assignments.
{
  imports = [
    ./alloy
    ./authentik
    ./babybuddy
    ./backup
    ./blocky
    ./caddy
    ./dell-idrac-fan-controller
    ./garage
    ./grafana
    ./headscale
    ./immich
    ./ittools
    ./jobscraper
    ./karakeep
    ./loki
    ./mailarchiver
    ./matrix
    ./mongodb
    ./nightscout
    ./opencloud
    ./podman
    ./postgresql
    ./prometheus
    ./ssh
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
