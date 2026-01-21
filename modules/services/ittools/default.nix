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
  options.homelab.services.ittools = {
    enable = lib.mkEnableOption "Whether to enable IT-Tools.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "ittools.mantannest.com";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 8901;
      type = lib.types.port;
    };
  };

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
            useACMEHost = ittoolsCfg.webDomain;
            extraConfig = ''
              reverse_proxy http://${ittoolsCfg.listenAddress}:${toString ittoolsCfg.listenPort}
            '';
          };
        };
      };
    };

    security = lib.mkIf (caddyEnabled && ittoolsCfg.enable) {
      acme.certs."${ittoolsCfg.webDomain}".domain = "${ittoolsCfg.webDomain}";
    };
  };
}
