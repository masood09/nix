{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  ittoolsCfg = homelabCfg.services.ittools;
  podmanEnabled = homelabCfg.services.podman.enable;
  caddyEnabled = config.services.caddy.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf (ittoolsCfg.enable && podmanEnabled) {
    virtualisation.oci-containers.containers.ittools = {
      image = "ghcr.io/corentinth/it-tools:latest";
      autoStart = true;

      extraOptions = [
        "--pull=newer"
      ];

      ports = [
        "${ittoolsCfg.listenAddress}:${toString ittoolsCfg.listenPort}:80"
      ];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${ittoolsCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://${ittoolsCfg.listenAddress}:${toString ittoolsCfg.listenPort}
            '';
          };
        };
      };
    };
  };
}
