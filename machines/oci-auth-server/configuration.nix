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

    # ./../../modules/nixos/auto-update.nix
    ./../../modules/nixos/base.nix
    ./../../modules/nixos/remote-unlock.nix

    ./../../services/authentik.nix
    ./../../services/systemd-resolved.nix
    ./../../services/tailscale.nix
    ./../../services/prometheus-exporter-node.nix
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
  };
}
