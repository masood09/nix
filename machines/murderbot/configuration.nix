{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    inputs.home-manager.darwinModules.home-manager

    ./hardware-configuration.nix

    ./../../modules/macos/base.nix
  ];

  homelab = {
    networking = {
      hostName = "murderbot";
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
          ./../../modules/home-manager/base.nix
          ./../../modules/home-manager/packages-dev.nix
          ./../../modules/home-manager/fonts.nix
          ./../../modules/home-manager/git.nix
        ];
      };
    };
  };
}
