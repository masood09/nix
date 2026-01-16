{
  imports = [
    ./alloy
    ./caddy
    ./immich
    ./minio
    ./postgresql
    ./ssh
  ];

  services = {
    fstrim.enable = true;
  };
}
