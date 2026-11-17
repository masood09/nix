# Options — LiteLLM gateway (container image, catalog, routing, Authentik SSO).
{
  config,
  lib,
  ...
}: let
  backendType = lib.types.submodule {
    options = {
      apiBase = lib.mkOption {
        type = lib.types.str;
        example = "http://ixian.dns.headscale.example.com:8922/v1";
        description = "OpenAI-compatible base URL of the engine.";
      };

      models = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Model names this engine serves; each is offered under the same name.";
      };
    };
  };
in {
  options = {
    homelab = {
      services = {
        litellm = {
          enable = lib.mkEnableOption "LiteLLM, the authenticated OpenAI-compatible gateway in front of the local engines";

          image = lib.mkOption {
            type = lib.types.str;
            # renovate: datasource=docker depName=ghcr.io/berriai/litellm-non_root
            default = "ghcr.io/berriai/litellm-non_root:v1.108.9@sha256:49164609b06c4c579ea2f277177061a3339c10f26268ec7baf27ce104c1bce13";
            description = ''
              Container image, pinned by tag and digest. Upstream signs every
              image with cosign; before changing the pin, verify the new digest
              against the key from upstream commit e82a3c6 (the key was rotated
              on 2026-10-23 after the October GHCR incident):
              `cosign verify --key https://raw.githubusercontent.com/BerriAI/litellm/e82a3c646908ba0a6ee0beddc4310d7a6cac4065/cosign.pub <image>@<digest>`.
            '';
          };

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "llm.${config.networking.domain}";
            defaultText = lib.literalExpression ''"llm.''${config.networking.domain}"'';
            description = "Hostname Caddy serves LiteLLM on (API under /v1, admin UI under /ui).";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8923;
            description = "Loopback port LiteLLM listens on behind Caddy (see docs/service-registry.org).";
          };

          environmentFile = lib.mkOption {
            type = lib.types.str;
            example = lib.literalExpression ''config.sops.templates."litellm.env".path'';
            description = ''
              Env file with the secrets: LITELLM_MASTER_KEY, LITELLM_SALT_KEY
              (never change it once set: it encrypts credentials stored in the
              DB), DATABASE_URL, BACKEND_KEY (sent to every engine), and
              GENERIC_CLIENT_SECRET when Authentik is enabled.
            '';
          };

          backends = lib.mkOption {
            type = lib.types.attrsOf backendType;
            default = {};
            description = "Engines LiteLLM routes to, keyed by a short name.";
          };

          aliases = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            example = {
              heavy = "qwen3.8-flash-next-iq3_s";
            };
            description = "Extra model names, each served by the backend of the model it points at.";
          };

          fallbacks = lib.mkOption {
            type = lib.types.attrsOf (lib.types.listOf lib.types.str);
            default = {};
            example = {
              heavy = ["light"];
            };
            description = ''
              Models to try, in order, when a model fails (any error, such as
              ixian's 503 while it is gaming). A key needs access to the
              fallback model too, or the fallback is refused.
            '';
          };

          requestTimeout = lib.mkOption {
            type = lib.types.ints.positive;
            default = 1800;
            description = ''
              Seconds a request (streaming included) may take. Covers a size
              switch on ixian, which can queue for up to model-router's maxWait.
            '';
          };

          authentik = {
            enable = lib.mkEnableOption "admin UI login through Authentik (generic OIDC)";

            url = lib.mkOption {
              type = lib.types.str;
              default = "https://auth.${config.networking.domain}";
              defaultText = lib.literalExpression ''"https://auth.''${config.networking.domain}"'';
              description = "Base URL of Authentik.";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "litellm";
              description = "Client ID of the Authentik OAuth2 provider (its redirect URI is https://<webDomain>/sso/callback).";
            };

            adminGroup = lib.mkOption {
              type = lib.types.str;
              default = "litellm-admins";
              description = ''
                Authentik group whose members get LiteLLM's proxy_admin role,
                read from the token's groups claim. Everyone else who can log
                in gets internal_user_viewer.
              '';
            };
          };
        };
      };
    };
  };
}
