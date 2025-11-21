{
  config,
  inputs,
  outputs,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./../../modules/nixos/pve-hardware-configuration.nix

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/distributed-builds-x86_64_linux.nix

    ./services/acme.nix
    ./services/nginx.nix
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

  homelab.networking = {
    hostName = "pve-proxy";
    primaryInterface = "ens18";
  };

  systemd.network.networks."tailscale0".dns = lib.mkForce [];
  systemd.network.networks."tailscale0".domains = lib.mkForce [];

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
