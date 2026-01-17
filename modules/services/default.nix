{
  imports = [
    ./alloy
    ./caddy
    ./immich
    ./minio
    ./postgresql
    ./ssh
    ./tailscale
    ./uptime-kuma
    ./zfs
  ];

  services = {
    fstrim.enable = true;
  };
}
