{
  inputs,
  outputs,
  vars,
  ...
}: {
  imports = [
    ./../../modules/nixos/oci-hardware-configuration.nix
    ./../../modules/nixos/oci-network-configuration.nix

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix

    ./services/acme.nix
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

  networking.hostName = "oci-proxy-server";

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
