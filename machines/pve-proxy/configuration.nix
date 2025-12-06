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

    ./../../modules/nixos/base.nix

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

  homelab = {
    isEncryptedRoot = false;

    networking = {
      hostName = "pve-proxy";
    };
  };

  systemd.network.networks."tailscale0".dns = lib.mkForce [];
  systemd.network.networks."tailscale0".domains = lib.mkForce [];

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
