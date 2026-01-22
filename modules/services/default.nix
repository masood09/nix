{
  imports = [
    ./alloy
    ./authentik
    ./babybuddy
    ./caddy
    ./dell-idrac-fan-controller
    ./garage
    ./grafana
    ./immich
    ./ittools
    ./jobscraper
    ./headscale
    ./loki
    ./podman
    ./postgresql
    ./prometheus
    ./restic
    ./ssh
    ./tailscale
    ./uptime-kuma
    ./vaultwarden
  ];

  services = {
    fstrim.enable = true;
  };
}
