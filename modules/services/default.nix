{
  imports = [
    ./alloy
    ./authentik
    ./caddy
    ./immich
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
