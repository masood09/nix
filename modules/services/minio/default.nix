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
in {
  disabledModules = ["services/web-servers/minio.nix"];

  imports = [
    "${inputs.nixpkgs-unstable}/nixos/modules/services/web-servers/minio.nix"
  ];

  services = {
    minio = {
      inherit (minioCfg) enable browser certificatesDir configDir dataDir rootCredentialsFile region;

      consoleAddress = "${minioCfg.consoleAddress}:${toString minioCfg.consolePort}";
      listenAddress = "${minioCfg.listenAddress}:${toString minioCfg.listenPort}";

      package = pkgs-unstable.minio;
    };
  };

  networking.firewall.allowedTCPPorts =
    lib.optionals minioCfg.openFirewall (
      [
        minioCfg.listenPort
      ]
        ++ lib.optionals minioCfg.browser [
          minioCfg.consolePort
        ]
    );
}
