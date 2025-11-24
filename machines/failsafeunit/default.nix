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

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix
  ];

  homelab = {
    networking = {
      hostName = "failsafeunit";
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

  # For systemd services (like nix-daemon)
  systemd = {
    extraConfig = ''
      DefaultLimitNOFILE=65536
      DefaultTimeoutStartSec=20s
      DefaultTimeoutStopSec=10s
    '';
  };
}
