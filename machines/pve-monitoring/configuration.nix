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
    ./../../modules/nixos/distributed-builds-x86_64_linux.nix

    ./../../services/grafana-alloy.nix
    ./../../services/systemd-resolved.nix
    ./../../services/tailscale.nix

    ./services/acme.nix
    ./services/nginx.nix
    ./services/grafana.nix
    ./services/grafana-loki.nix
    ./services/restic.nix
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
          ./../../modules/home-manager/packages-server.nix
        ];
      };
    };
  };

  networking = {
    hostName = "pve-monitoring";
    dhcpcd.enable = false;
    useNetworkd = true;
    interfaces.ens18.useDHCP = true;
  };
}
