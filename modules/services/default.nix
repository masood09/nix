{
  imports = [
    ./alloy
    ./authentik
    ./caddy
    ./immich
    ./headscale
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
