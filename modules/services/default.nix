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
    ./zfs
  ];

  services = {
    fstrim.enable = true;
  };
}
