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

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix

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
      primaryInterface = "enp1s0";
    };

    programs = {
      emacs.enable = false;
      neovim.enable = false;
      zsh.enable = false;
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
}
