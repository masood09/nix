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

    ./../../modules/nixos/base.nix

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
    };
  };

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
