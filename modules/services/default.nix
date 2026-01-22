{
  imports = [
    ./alloy
    ./authentik
    ./babybuddy
    ./caddy
    ./dell-idrac-fan-controller
    ./grafana
    ./immich
    ./ittools
    ./jobscraper
    ./headscale
    ./loki
    ./minio
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
