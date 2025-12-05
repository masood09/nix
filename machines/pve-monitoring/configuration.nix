{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./../../modules/nixos/pve-hardware-configuration.nix

    ./../../modules/nixos/base.nix

    ./services/acme.nix
    ./services/nginx.nix
    ./services/grafana.nix
    ./services/grafana-loki.nix
    ./services/prometheus.nix
    ./services/restic.nix
  ];

  services = {
    qemuGuest.enable = true;
  };

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs homelabCfg;
    };

    useGlobalPkgs = true;
    useUserPackages = true;

    users = {
      ${homelabCfg.primaryUser.userName} = {
        imports = [
          ./../../modules/home-manager
        ];
      };
    };
  };

  homelab = {
    isEncrypedRoot = false;

    networking = {
      hostName = "pve-monitoring";
    };
  };

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
