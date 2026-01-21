{
  imports = [
    ./alloy
    ./authentik
    ./babybuddy
    ./caddy
    ./immich
    ./ittools
    ./jobscraper
    ./headscale
    ./loki
    ./minio
    ./podman
    ./postgresql
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
