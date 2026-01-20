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
    ./vaultwarden
  ];

  services = {
    fstrim.enable = true;
  };
}
