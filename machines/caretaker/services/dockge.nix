{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  virtualisation.oci-containers.containers.dockge = {
    image = "louislam/dockge:1";
    autoStart = true;

    extraOptions = [
      "--pull=newer"
    ];

    volumes = [
      "/var/lib/dockge/data:/app/data"
      "/var/lib/dockge/stacks:/var/lib/dockge/stacks"
      "/var/run/podman/podman.sock:/var/run/docker.sock"
    ];

    ports = [
      "127.0.0.1:5001:5001"
    ];

    environment = {
      DOCKGE_STACKS_DIR = "/var/lib/dockge/stacks";
    };
  };

  environment.persistence."/nix/persist" = lib.mkIf (!homelabCfg.isRootZFS) {
    directories = [
      "/var/lib/dockge"
    ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/dockge 0700 root root -"
    "d /var/lib/dockge/data 0700 root root -"
    "d /var/lib/dockge/stacks 0700 root root -"
  ];
}
