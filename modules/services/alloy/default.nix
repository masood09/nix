{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  alloyCfg = config.homelab.services.alloy;
in {
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
