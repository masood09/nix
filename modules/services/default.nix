{
  imports = [
    ./alloy
    ./caddy
    ./immich
    ./minio
    ./postgresql
    ./ssh
    ./uptime-kuma
  ];

  services = {
    fstrim.enable = true;
  };
}
