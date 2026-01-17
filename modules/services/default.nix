{
  imports = [
    ./alloy
    ./caddy
    ./immich
    ./minio
    ./postgresql
    ./ssh
    ./uptime-kuma
    ./zfs
  ];

  services = {
    fstrim.enable = true;
  };
}
