{
  imports = [
    ./alloy
    ./authentik
    ./caddy
    ./immich
    ./headscale
    ./minio
    ./postgresql
    ./restic
    ./ssh
    ./tailscale
    ./uptime-kuma
  ];

  services = {
    fstrim.enable = true;
  };
}
