{
  config,
  lib,
  ...
}: let
  authentikCfg = config.homelab.services.authentik;
  caddyEnabled = config.homelab.services.caddy.enable;
  postgresqlEnabled = config.homelab.services.postgresql.enable;
  postgresqlBackupEnabled = config.homelab.services.postgresql.backup.enable;
in {
  imports = [
    ./alloy.nix
  ];

  options.homelab.services.authentik = {
    enable = lib.mkEnableOption "Whether to enable Authentik.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "auth.mantannest.com";
    };
  };

  config = lib.mkIf authentikCfg.enable {
    services = {
      authentik = {
        inherit (authentikCfg) enable;

        environmentFile = config.sops.secrets."authentik.env".path;

        settings = {
          disable_startup_analytics = true;
          avatars = "initials";
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${authentikCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:9000
            '';
          };
        };
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled) {
        databases = [
          "authentik"
        ];
      };
    };
  };
}
