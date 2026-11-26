# Options — Open WebUI chat front end (domain, port, LiteLLM backend, OIDC, ZFS).
{
  config,
  lib,
  ...
}: let
  zfsOpts = (import ../../../lib/zfs-options.nix {inherit lib;}).mkZfsOptions;
in {
  options = {
    homelab = {
      services = {
        open-webui = {
          enable = lib.mkEnableOption "Open WebUI, the chat front end for the LiteLLM gateway";

          webDomain = lib.mkOption {
            type = lib.types.str;
            # Not chat.<domain>: that is Matrix's rootDomain (Synapse client
            # API and .well-known discovery), so reusing it would collide on
            # the Caddy vhost and break federation.
            default = "llmchat.${config.networking.domain}";
            defaultText = lib.literalExpression ''"llmchat.''${config.networking.domain}"'';
            description = "Public hostname for Open WebUI.";
          };

          dataDir = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/open-webui";
            description = "State directory (SQLite DB, uploads, vector DB, embedding model cache).";
          };

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address on which Open WebUI listens behind Caddy.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8924;
            description = "Port on which Open WebUI listens (see docs/service-registry.org).";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3023;
            description = "UID for the Open WebUI service user.";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3023;
            description = "GID for the Open WebUI service group.";
          };

          inference = {
            baseUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://llm.${config.networking.domain}/v1";
              defaultText = lib.literalExpression ''"https://llm.''${config.networking.domain}/v1"'';
              description = ''
                OpenAI-compatible endpoint: the LiteLLM gateway on mentat.
                OPENAI_API_KEY in the sops .env is Open WebUI's own LiteLLM
                virtual key.
              '';
            };

            mcpUrl = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = "https://llm.${config.networking.domain}/mcp";
              defaultText = lib.literalExpression ''"https://llm.''${config.networking.domain}/mcp"'';
              description = ''
                LiteLLM's MCP gateway, added as one tool connection for Open
                WebUI admins only (no access grants). It authenticates with the
                same OPENAI_API_KEY, whose LiteLLM grants decide the servers.
                Null leaves it out.
              '';
            };
          };

          oidc = {
            providerUrl = lib.mkOption {
              type = lib.types.str;
              default = "https://auth.${config.networking.domain}/application/o/openwebui/.well-known/openid-configuration";
              defaultText = lib.literalExpression ''"https://auth.''${config.networking.domain}/application/o/openwebui/.well-known/openid-configuration"'';
              description = ''
                Authentik OpenID discovery URL. The provider's redirect URI is
                https://<webDomain>/oauth/oidc/callback; OAUTH_CLIENT_SECRET
                lives in the sops .env.
              '';
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "openwebui";
              description = "OpenID client ID for Open WebUI.";
            };
          };

          zfs = zfsOpts {
            serviceName = "Open WebUI";
            dataset = "dpool/tank/services/open-webui";
            properties = {
              logbias = "latency";
              recordsize = "16K";
            };
            withRestic = true;
          };
        };
      };
    };
  };
}
