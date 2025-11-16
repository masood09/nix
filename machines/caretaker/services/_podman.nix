{pkgs, ...}: {
  virtualisation.podman.enable = true;

  environment.systemPackages = with pkgs; [
    podman-compose
  ];

  environment.persistence."/nix/persist" = {
    directories = [
      "/var/lib/containers"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/containers 0700 root root -"
  ];
}
