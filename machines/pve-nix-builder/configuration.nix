{
  config,
  inputs,
  outputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  imports = [
    ./../../modules/nixos/pve-hardware-configuration.nix

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
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
          ./../../modules/home-manager/base.nix
          ./../../modules/home-manager/packages-server.nix
        ];
      };
    };
  };

  users = {
    users.remotebuild = {
      isSystemUser = true;
      group = "remotebuild";
      useDefaultShell = true;

      openssh.authorizedKeys.keyFiles = [
        ./../../files/ssh/pve-app-1.pub
        ./../../files/ssh/pve-database.pub
        ./../../files/ssh/pve-monitoring.pub
        ./../../files/ssh/pve-proxy.pub
      ];
    };

    groups.remotebuild = {};
  };

  nix.settings.trusted-users = ["remotebuild"];

  homelab.networking = {
    hostName = "pve-nix-builder";
    primaryInterface = "ens18";
  };
}
