{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
  };

  minioCfg = config.homelab.services.minio;
  caddyEnabled = config.homelab.services.caddy.enable;
in {
  disabledModules = ["services/web-servers/minio.nix"];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-servers/minio.nix"
  ];

  services = lib.mkIf minioCfg.enable {
    minio = {
      inherit (minioCfg) enable browser certificatesDir configDir dataDir rootCredentialsFile region;

      consoleAddress = "${minioCfg.consoleAddress}:${toString minioCfg.consolePort}";
      listenAddress = "${minioCfg.listenAddress}:${toString minioCfg.listenPort}";

      package = pkgs-unstable.minio;
    };

    caddy = lib.mkIf caddyEnabled {
      virtualHosts = {
        "${minioCfg.s3Host}" = {
          useACMEHost = minioCfg.s3Host;
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString minioCfg.listenPort}
          '';
        };

        "${minioCfg.adminHost}" = lib.mkIf minioCfg.browser {
          useACMEHost = minioCfg.adminHost;
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString minioCfg.consolePort}
          '';
        };
      };
    };
  };

  security = lib.mkIf (caddyEnabled && minioCfg.enable) {
    acme = {
      certs = {
        "${minioCfg.s3Host}".domain = "${minioCfg.s3Host}";

        "${minioCfg.adminHost}" = lib.mkIf minioCfg.browser {
          domain = "${minioCfg.adminHost}";
        };
      };
    };
  };

  networking.firewall.allowedTCPPorts =
    lib.mkIf minioCfg.openFirewall (
      [
        minioCfg.listenPort
      ]
      ++ lib.optionals minioCfg.browser [
        minioCfg.consolePort
      ]
    );
}
