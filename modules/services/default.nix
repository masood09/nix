{
  imports = [
    ./alloy
    ./authentik
    ./babybuddy
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
