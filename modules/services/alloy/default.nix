{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  alloyCfg = config.homelab.services.alloy;

  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
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
      inherit (alloyCfg) enable;

      environmentFile = config.sops.secrets."grafana-alloy-env".path;

      extraFlags = [
        "--disable-reporting"
      ];

      package = pkgs-unstable.grafana-alloy;
    };
  };

  systemd.services = lib.mkIf alloyCfg.enable {
    alloy = {
      environment = {
        ALLOY_HOSTNAME = config.homelab.networking.hostName;
      };
    };
  };

  environment.etc."alloy/config.alloy" = lib.mkIf alloyCfg.enable {
    source = ./config.alloy;
  };
}
