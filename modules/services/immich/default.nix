{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  immichCfg = config.homelab.services.immich;
  postgresqlEnabled = config.homelab.services.postgresql.enable;
  caddyEnabled = config.homelab.services.caddy.enable;

  pkgs-unstable = import inputs.nixpkgs-unstable {
    inherit (pkgs) system;
  };
in {
  disabledModules = ["services/web-apps/immich.nix"];

  imports = [
    ./immich-services.nix
  ];

  services = lib.mkIf immichCfg.enable {
    immich = {
      inherit (immichCfg) enable mediaLocation;
      package = pkgs-unstable.immich;

      database = {
        enable = postgresqlEnabled;
        enableVectors = false;
      };
    };

    caddy = lib.mkIf caddyEnabled {
      virtualHosts = {
        "${immichCfg.webDomain}" = {
          useACMEHost = immichCfg.webDomain;
          extraConfig = ''
            reverse_proxy http://127.0.0.1:${toString config.services.immich.port}
          '';
        };
      };
    };
  };

  security = lib.mkIf (caddyEnabled && immichCfg.enable) {
    acme.certs."${immichCfg.webDomain}".domain = "${immichCfg.webDomain}";
  };

  users.users = lib.optionalAttrs (immichCfg.enable) {
    immich.uid = immichCfg.userId;
  };

  users.groups = lib.optionalAttrs (immichCfg.enable) {
    immich.gid = immichCfg.groupId;
  };
}
