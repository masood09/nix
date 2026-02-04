{
  config,
  lib,
  ...
}: let
  authentikCfg = config.homelab.services.authentik;
  caddyEnabled = config.homelab.services.caddy.enable;
  postgresqlEnabled = config.homelab.services.postgresql.enable;
  postgresqlBackupEnabled = config.homelab.services.postgresql.backup.enable;
  alloyEnabled = config.homelab.services.alloy.enable;
in {
  imports = [
    ./alloy.nix
  ];

  options.homelab.services.authentik = {
    enable = lib.mkEnableOption "Whether to enable Authentik.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "auth.${config.networking.domain}";
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

    # -------------------------
    # Loki drop rules (Alloy)
    # -------------------------
    homelab.services.alloy.loki.systemd.dropRules = lib.mkIf alloyEnabled (lib.mkAfter [
      {
        name = "authentik: drop /-/health/live/ 200";
        unit = "authentik.service";
        expression = ".*\"event\"\\s*:\\s*\"/-/health/live/\".*\"status\"\\s*:\\s*200.*";
      }
      {
        name = "authentik: drop /-/metrics/ 200";
        unit = "authentik.service";
        expression = ".*\"event\"\\s*:\\s*\"/-/metrics/\".*\"status\"\\s*:\\s*200.*";
      }
    ]);
  };
}
