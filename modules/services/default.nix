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
    fstrim.enable = true;
  };
}
