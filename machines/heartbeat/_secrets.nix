# Sops secret declarations — paths, owners, and restart triggers for this machine.
{
  config = {
    sops = {
      secrets = {
        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        # Arr media stack (nixflix) — see modules/services/arr/. API keys can be
        # generated with `uuidgen | base64`; web-UI passwords are your choice.
        "arr/jellyfin/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "jellyfin";
          restartUnits = ["jellyfin.service"];
        };

        "arr/jellyfin/admin-password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "jellyfin";
          restartUnits = ["jellyfin.service"];
        };

        "arr/jellyfin/ldap-bind-password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "jellyfin";
          restartUnits = ["jellyfin-plugins.service"];
        };

        "arr/sonarr/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sonarr";
          restartUnits = ["sonarr.service"];
        };

        "arr/sonarr/password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sonarr";
          restartUnits = ["sonarr.service"];
        };

        "arr/radarr/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "radarr";
          restartUnits = ["radarr.service"];
        };

        "arr/radarr/password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "radarr";
          restartUnits = ["radarr.service"];
        };

        "arr/prowlarr/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "prowlarr";
          restartUnits = ["prowlarr.service"];
        };

        "arr/prowlarr/password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "prowlarr";
          restartUnits = ["prowlarr.service"];
        };

        "arr/sabnzbd/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sabnzbd";
          restartUnits = ["sabnzbd.service"];
        };

        "arr/sabnzbd/nzb-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sabnzbd";
          restartUnits = ["sabnzbd.service"];
        };

        "arr/sabnzbd/username" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sabnzbd";
          restartUnits = ["sabnzbd.service"];
        };

        "arr/sabnzbd/password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sabnzbd";
          restartUnits = ["sabnzbd.service"];
        };

        "arr/seerr/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "seerr";
          restartUnits = ["seerr.service"];
        };

        "arr/usenet/frugalusenet/username" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sabnzbd";
          restartUnits = ["sabnzbd.service"];
        };

        "arr/usenet/frugalusenet/password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sabnzbd";
          restartUnits = ["sabnzbd.service"];
        };

        "arr/indexers/nzbgeek/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "prowlarr";
          restartUnits = ["prowlarr.service"];
        };

        "arr/indexers/nzbplanet/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "prowlarr";
          restartUnits = ["prowlarr.service"];
        };

        "caddy/.env" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "caddy";
          restartUnits = ["caddy.service"];
        };

        "cloudflare/api-key" = {
          restartUnits = ["acme-setup.service"];
        };

        "dell-idrac-fan-controller/.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["podman-dell-idrac-fan-controller.service"];
        };

        "dpool_tank_key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "fpool_fast_key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "grafana/authentik-client-secret" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "grafana";
          restartUnits = ["grafana.service"];
        };

        "grafana/secret-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "grafana";
          restartUnits = ["grafana.service"];
        };

        # Local break-glass admin password (Authentik-down fallback). Add the
        # value with `sops machines/heartbeat/secrets.sops.yaml`.
        "grafana/admin-password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "grafana";
          restartUnits = ["grafana.service"];
        };

        # Discord alerting webhook URLs (env file: DISCORD_CRITICAL_WEBHOOK,
        # DISCORD_WARNING_WEBHOOK, DISCORD_EVENTS_WEBHOOK). Mounted as Grafana's
        # EnvironmentFile; referenced by the provisioned contact points via $__env.
        "grafana/discord-webhooks.env" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "grafana";
          restartUnits = ["grafana.service"];
        };

        "jobscraper/.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["podman-jobscraper.service"];
        };

        "karakeep/.env" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "karakeep";
          restartUnits = [
            "karakeep-web.service"
            "karakeep-workers.service"
          ];
        };

        "mailarchiver/.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["mailarchiver.service"];
        };

        "matrix/mas/matrix-secret" = {
          owner = "matrix-authentication-service";
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["matrix-authentication-service.service"];
        };

        "matrix/mas/upstream-oauth2.config" = {
          owner = "matrix-authentication-service";
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["matrix-authentication-service.service"];
        };

        "matrix/mas/secrets.config" = {
          owner = "matrix-authentication-service";
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["matrix-authentication-service.service"];
        };

        "matrix/synapse/mas-secret" = {
          owner = "matrix-synapse";
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["matrix-synapse.service"];
        };

        "mongodb/root-password" = {
          owner = "mongodb";
          sopsFile = ./secrets.sops.yaml;
        };

        "nightscout/.env" = {
          owner = "nightscout";
          sopsFile = ./secrets.sops.yaml;
        };

        "opencloud/collabora/.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["podman-compose-opencloud-root.target"];
        };

        "opencloud/opencloud/.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["podman-compose-opencloud-root.target"];
        };

        "restic/.env" = {
          sopsFile = ./secrets.sops.yaml;
        };
        "restic/repo" = {
          sopsFile = ./secrets.sops.yaml;
        };
        "restic/password" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "tailscale/preauth-key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "vaultwarden/.env" = {
          sopsFile = ./secrets.sops.yaml;
          restartUnits = ["vaultwarden.service"];
        };

        "zed/discord-zfs-webhook" = {};
      };
    };
  };
}
