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

    ./../../modules/macos/base.nix
  ];

  homelab = {
    networking = {
      hostName = "murderbot";
    };

    programs = {
      emacs.enable = true;
      neovim.enable = true;
      zsh.enable = true;
    };

    role = "desktop";
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
