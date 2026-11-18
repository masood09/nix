# Sops secret declarations — paths, owners, and restart triggers for this machine.
{
  config = {
    sops = {
      secrets = {
        # Authentik OIDC client secret for Actual Budget, keyed like the
        # Authentik app (actualbudget). Upstream's preStart reads it as the
        # actual user while rendering /run/actual/config.json. Rotation
        # touches both this file and infra-tofu's authentik apps.sops.json.
        "actualbudget/oidc/client-secret" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "actual";
          restartUnits = ["actual.service"];
        };

        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        # Shared backend key (secrets/secrets.sops.yaml): LiteLLM on mentat
        # sends it to llama.cpp here and to model-router on ixian. One line,
        # at least 16 characters. Rotating it touches all three hosts.
        "llm/backend-key" = {
          owner = "llama-cpp";
          restartUnits = ["llama-cpp.service"];
        };

        # Shared with mentat (secrets/secrets.sops.yaml), whose LiteLLM puts
        # it in DATABASE_URL, so keep it URL-safe (letters and digits).
        # postgresql-litellm-password sets it on the litellm role.
        "litellm/db-password" = {
          owner = "postgres";
          restartUnits = ["postgresql-litellm-password.service"];
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

        "arr/navidrome/admin-password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "navidrome";
          restartUnits = ["navidrome.service"];
        };

        "aurral/last-fm/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "navidrome";
          restartUnits = ["navidrome.service"];
        };

        "aurral/last-fm/api-secret" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "navidrome";
          restartUnits = ["navidrome.service"];
        };

        "aurral/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "aurral";
          restartUnits = ["aurral.service"];
        };

        "aurral/oidc-client-secret" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "aurral";
          restartUnits = ["aurral.service"];
        };

        "arr/sonarr/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "sonarr";
          restartUnits = ["sonarr.service"];
        };

        "arr/radarr/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "radarr";
          restartUnits = ["radarr.service"];
        };

        "arr/lidarr/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "lidarr";
          restartUnits = ["lidarr.service"];
        };

        "arr/slskd/web-username" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "slskd";
          restartUnits = ["slskd-env.service"];
        };

        "arr/slskd/web-password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "slskd";
          restartUnits = ["slskd-env.service"];
        };

        "arr/slskd/api-key" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "slskd";
          restartUnits = ["slskd-env.service"];
        };

        "arr/slskd/soulseek-username" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "slskd";
          restartUnits = ["slskd-env.service"];
        };

        "arr/slskd/soulseek-password" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "slskd";
          restartUnits = ["slskd-env.service"];
        };

        "arr/vpn/proton-wireguard-config" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "arr/prowlarr/api-key" = {
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

        # WEBUI_SECRET_KEY, OPENAI_API_KEY (Open WebUI's LiteLLM virtual key)
        # and OAUTH_CLIENT_SECRET (Authentik provider "openwebui").
        "open-webui/.env" = {
          sopsFile = ./secrets.sops.yaml;
          owner = "open-webui";
          restartUnits = ["open-webui.service"];
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
