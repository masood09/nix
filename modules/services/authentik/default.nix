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
  options.homelab.services.authentik = {
    enable = lib.mkEnableOption "Whether to enable Authentik.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "auth.mantannest.com";
    };

    listenPort = lib.mkOption {
      default = 9001;
      type = lib.types.port;
      description = "The port of the authentik server.";
    };

    listenMetricsPort = lib.mkOption {
      default = 9301;
      type = lib.types.port;
      description = "The port for metrics";
    };
  };

  config = lib.mkIf authentikCfg.enable {
    services = {
      authentik = {
        inherit (authentikCfg) enable;

        environmentFile = config.sops.secrets."authentik-env".path;

        settings = {
          disable_startup_analytics = true;
          avatars = "initials";
        };

        worker = {
          listenHTTP = "127.0.0.1:${toString config.homelab.services.authentik.listenPort}";
          listenMetrics = "127.0.0.1:${toString config.homelab.services.authentik.listenMetricsPort}";
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${authentikCfg.webDomain}" = {
            useACMEHost = authentikCfg.webDomain;
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

    security = lib.mkIf caddyEnabled {
      acme.certs."${authentikCfg.webDomain}".domain = "${authentikCfg.webDomain}";
    };

    environment.persistence."/nix/persist" = {
      directories = [
        "/var/lib/private/authentik/media"
      ];
    };
  };
}
