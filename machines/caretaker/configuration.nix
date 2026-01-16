{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./hardware-configuration.nix

    ./../../modules/nixos/base.nix

    ./services/_podman.nix
    ./services/acme.nix
    ./services/blocky.nix
    ./services/dockge.nix
    ./services/homeassistant.nix
    ./services/nginx.nix
  ];

  homelab = {
    networking = {
      hostName = "caretaker";
    };

    services = {
      ssh = {
        listenPort = 22;
        listenPortBoot = 2222;
      };
    };
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

  services.tailscale = {
    useRoutingFeatures = "both";

    extraUpFlags = [
      "--advertise-exit-node"
      "--advertise-routes=10.0.0.0/16"
    ];
  };
}
