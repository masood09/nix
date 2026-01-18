{
  imports = [
    ./alloy
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
