{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./disko
    ./hardware-configuration.nix
    ./_networking.nix

    ./../../modules/nixos/base.nix

    # ./../../modules/services
  ];

  homelab = {
    isRootZFS = true;

    networking = {
      hostName = "nastest";
    };

    services = {
      ssh = {
        listenPort = 22;
        listenPortBoot = 22;
      };
    };
  };

  fileSystems = {
    "/".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/var/lib/nixos".neededForBoot = true;
    "/nix".neededForBoot = true;
    "/nix/persist".neededForBoot = true;
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
