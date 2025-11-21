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
    ./services/headscale.nix
    ./services/restic.nix
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
          ./../../modules/home-manager/base.nix
          ./../../modules/home-manager/packages-server.nix
        ];
      };
    };
  };

  networking = {
    hostName = "oci-vpn-server";
    dhcpcd.enable = false;
    useNetworkd = true;
    interfaces.enp0s6.useDHCP = true;

    hosts = {
      "100.64.0.7" = [
        "loki.monitoring.server.mantannest.com"
        "prometheus.monitoring.server.mantannest.com"
      ];
    };
  };

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
