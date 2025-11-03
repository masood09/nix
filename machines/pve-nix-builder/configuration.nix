{
  inputs,
  outputs,
  vars,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence

    ./../../modules/nixos/pve-hardware-configuration.nix

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix

    ./../../services/systemd-resolved.nix
    ./../../services/tailscale.nix
  ];

  services = {
    qemuGuest.enable = true;
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs vars;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      ${vars.userName} = {
        imports = [
          ./../../modules/home-manager/base.nix
        ];
      };
    };
  };

  networking = {
    hostName = "pve-nix-builder";
    dhcpcd.enable = false;
    useNetworkd = true;
    interfaces.ens18.useDHCP = true;
  };

  environment.persistence."/nix/persist" = {
    directories = [
      {
        directory = "/home/${vars.userName}/.ssh";
        user = vars.userName;
      }
    ];
  };
}
