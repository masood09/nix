{
  inputs,
  outputs,
  vars,
  ...
}: {
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

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs vars;};
    useGlobalPkgs = true;
    useUserPackages = true;
    users = {
      ${vars.userName} = {
        imports = [
          ./../../modules/home-manager/base.nix
          ./../../modules/home-manager/packages-server.nix
        ];
      };
    };
  };
}
