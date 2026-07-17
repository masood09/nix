# Authentik — identity provider (SSO/OIDC) for all homelab services.
# Integrates with Caddy reverse proxy, PostgreSQL, and Alloy log filtering.
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
    ./options.nix
  ];

  config = lib.mkIf authentikCfg.enable {
    assertions = [
      {
        assertion = postgresqlEnabled;
        message = "Authentik requires PostgreSQL (homelab.services.postgresql.enable)";
      }
    ];
    services = {
      authentik = {
        inherit (authentikCfg) enable;

        environmentFile = config.sops.secrets."authentik/.env".path;

        settings = {
          disable_startup_analytics = true;
          avatars = "initials";
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${authentikCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            # authentik 2026.5.x serves the app only on its HTTPS listener (:9443);
            # the plain-HTTP :9000 listener returns empty 200s for every route.
            # Proxy to :9443 and skip verification of authentik's internal
            # self-signed cert (the upstream authentik-nix nginx example does the same).
            extraConfig = ''
              reverse_proxy https://127.0.0.1:9443 {
                transport http {
                  tls_insecure_skip_verify
                }
              }
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
    homelab = {
      services = {
        alloy = {
          loki = {
            systemd = {
              dropRules = lib.mkIf alloyEnabled (lib.mkAfter [
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
          };
        };
      };
    };
  };
}
