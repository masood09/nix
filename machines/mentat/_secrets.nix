# Sops secret declarations — paths, owners, and restart triggers for this machine.
{config, ...}: let
  ph = config.sops.placeholder;
in {
  config = {
    sops = {
      secrets = {
        "alloy/.env" = {
          restartUnits = ["alloy.service"];
        };

        # Shared Cloudflare DNS token for the wildcard ACME certificate Caddy
        # serves llm.mantannest.com with.
        "cloudflare/api-key" = {
          restartUnits = ["acme-setup.service"];
        };

        # LiteLLM. The shared ones (secrets/secrets.sops.yaml) are also used
        # on heartbeat (llama.cpp, Postgres) and ixian (model-router); the
        # rest are mentat's own. They only reach LiteLLM through the env file
        # below, so they stay root-only.
        "llm/backend-key" = {};
        "litellm/db-password" = {};
        "litellm/master-key" = {
          sopsFile = ./secrets.sops.yaml;
        };
        # Encrypts the credentials LiteLLM stores in its database. Never
        # change it once set, or those become unreadable.
        "litellm/salt-key" = {
          sopsFile = ./secrets.sops.yaml;
        };
        # Client secret of the Authentik OAuth2 provider (client id litellm).
        "litellm/authentik-client-secret" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "tailscale/preauth-key" = {
          sopsFile = ./secrets.sops.yaml;
        };

        "zed/discord-zfs-webhook" = {};
      };

      templates = {
        # Read by Podman (root) as the container's --env-file.
        "litellm.env" = {
          content = ''
            LITELLM_MASTER_KEY=${ph."litellm/master-key"}
            LITELLM_SALT_KEY=${ph."litellm/salt-key"}
            DATABASE_URL=postgresql://litellm:${ph."litellm/db-password"}@heartbeat.dns.headscale.mantannest.com:5432/litellm
            BACKEND_KEY=${ph."llm/backend-key"}
            GENERIC_CLIENT_SECRET=${ph."litellm/authentik-client-secret"}
          '';
          restartUnits = ["podman-litellm.service"];
        };
      };
    };
  };
}
