{
  inputs,
  outputs,
  vars,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence

    ./../../modules/nixos/oci-hardware-configuration.nix

    ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix

    ./../../services/_acme.nix

    ./services/nginx.nix
    ./services/postgresql.nix
    ./services/redis.nix
    ./services/restic.nix
    ./services/authentik.nix
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

  networking = {
    hostName = "oci-auth-server";
    dhcpcd.enable = false;
    useNetworkd = true;
    interfaces.enp0s6.useDHCP = true;

    hosts = {
      "100.64.0.7" = [
        "loki.monitoring.server.mantannest.com"
        "prometheus.monitoring.server.mantannest.com"
      ];
    };
  };

  users.users.alloy = {
    extraGroups = ["nginx"];
  };

  environment.etc."alloy/config-nginx.alloy".source = ./../../files/alloy/config-nginx.alloy;
}
