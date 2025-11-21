{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./../../modules/nixos/oci-hardware-configuration.nix

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix

    ./services/acme.nix
    ./services/nginx.nix
    ./services/postgresql.nix
    ./services/redis.nix
    ./services/restic.nix
    ./services/authentik.nix
  ];

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
    networking = {
      hostName = "oci-auth-server";
      primaryInterface = "enp0s6";

      extraHosts = ''
        100.64.0.7 loki.monitoring.server.mantannest.com
        100.64.0.7 prometheus.monitoring.server.mantannest.com
      '';
    };
  };

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
