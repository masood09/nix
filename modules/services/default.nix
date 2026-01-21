{
  imports = [
    ./alloy
    ./authentik
    ./babybuddy
    ./caddy
    ./immich
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
