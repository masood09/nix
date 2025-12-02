{
  config,
  inputs,
  pkgs,
  ...
}: {
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
    };
  };

  networking.firewall.allowedTCPPorts = [12345];

  environment.etc."alloy/config.alloy".source = ../files/alloy/config.alloy;
}
