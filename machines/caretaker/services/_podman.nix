{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  virtualisation.podman.enable = true;

  environment.systemPackages = with pkgs; [
    podman-compose
  ];

  environment.persistence."/nix/persist" = lib.mkIf (!homelabCfg.isRootZFS) {
    directories = [
      "/var/lib/containers"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/containers 0700 root root -"
  ];
}
