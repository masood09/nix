{
  config,
  inputs,
  pkgs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
    config.allowUnfree = true;
  };
in {
  disabledModules = ["services/monitoring/alloy.nix"];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/monitoring/alloy.nix"
  ];

  sops.secrets = {
    "grafana-alloy-env" = {};
  };

  services = {
    alloy = {
      enable = true;

      environmentFile = config.sops.secrets."grafana-alloy-env".path;

      extraFlags = [
        "--disable-reporting"
      ];

      package = pkgs-unstable.grafana-alloy;
    };
  };

  networking.firewall.allowedTCPPorts = [12345];

  environment.etc."alloy/config.alloy".source = ../files/alloy/config.alloy;
}
