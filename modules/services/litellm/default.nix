# LiteLLM — the authenticated OpenAI-compatible gateway in front of the local
# engines (model-router/Strata on ixian, llama.cpp on heartbeat):
#
#   client ──https──> Caddy (webDomain) ──> LiteLLM (127.0.0.1:listenPort)
#                                             ├─> engine A over the tailnet
#                                             └─> engine B over the tailnet
#
# It runs the upstream non-root image under Podman rather than the nixpkgs
# module: per-client virtual keys, spend tracking and UI login need LiteLLM's
# database, and nixpkgs' Prisma has no query engine wired, so it would
# download one on first start. The image ships Prisma's engines and runs it
# offline (PRISMA_OFFLINE_MODE). It runs as the image's own user (65534).
#
# Host networking, so the container resolves the engines' MagicDNS names and
# the database host the same way the host does, and LiteLLM is bound to
# loopback with --host (nothing opens listenPort in the firewall).
#
# Routing: every engine model is offered under its own name; aliases add a
# name for an existing model, and fallbacks name what to try when a model
# fails. num_retries is 0 on purpose: a retry would re-enter model-router's
# switch queue from the start, while a fallback goes to another engine.
#
# Keys: the master key is for bootstrap and admin only. Clients get virtual
# keys, created in the UI or API, each limited to its models (a fallback
# model must be allowed too).
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.litellm;
  caddyEnabled = config.services.caddy.enable;

  yaml = pkgs.formats.yaml {};

  deployment = name: backend: model: {
    model_name = name;
    litellm_params = {
      model = "openai/${model}";
      api_base = backend.apiBase;
      api_key = "os.environ/BACKEND_KEY";
    };
    model_info =
      {
        max_input_tokens = backend.contextLength;
        max_output_tokens = backend.maxOutputTokens;
      }
      // lib.optionalAttrs (backend.pricing != null) {
        input_cost_per_token = backend.pricing.inputCostPerToken;
        output_cost_per_token = backend.pricing.outputCostPerToken;
      };
  };

  # Model name -> its backend, to resolve aliases.
  backendOf = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (
      _: b: map (m: lib.nameValuePair m b) b.models
    )
    cfg.backends));

  modelList =
    lib.concatLists (lib.mapAttrsToList (_: b: map (m: deployment m b m) b.models) cfg.backends)
    ++ lib.mapAttrsToList (alias: target: deployment alias backendOf.${target} target) cfg.aliases;

  configFile = yaml.generate "litellm-config.yaml" {
    model_list = modelList;

    general_settings =
      {
        master_key = "os.environ/LITELLM_MASTER_KEY";
        database_url = "os.environ/DATABASE_URL";
        # Caddy on loopback is the only proxy: its X-Forwarded-For then
        # attributes failed UI sign-ins to the real client, which turns on
        # the per-address limit. No header-based auth mode is enabled, so it
        # trusts nothing else.
        trusted_proxy_ranges = [
          "127.0.0.1/32"
        ];
      }
      // lib.optionalAttrs cfg.authentik.enable {
        # The master key stays an API credential only: with SSO, it no longer
        # signs in to the UI as proxy admin, so UI access always goes through
        # Authentik (and its MFA).
        disable_env_credential_login = true;
      };

    litellm_settings = {
      request_timeout = cfg.requestTimeout;
    };

    router_settings = {
      num_retries = 0;
      fallbacks = lib.mapAttrsToList (model: to: {${model} = to;}) cfg.fallbacks;
      # A held ixian answers at once, so one failure is enough to stop
      # sending to it for a while, and the fallback serves meanwhile.
      allowed_fails = 1;
      cooldown_time = 30;
    };
  };

  authentikEnv = lib.optionalAttrs cfg.authentik.enable {
    PROXY_BASE_URL = "https://${cfg.webDomain}";
    GENERIC_CLIENT_ID = cfg.authentik.clientId;
    GENERIC_AUTHORIZATION_ENDPOINT = "${cfg.authentik.url}/application/o/authorize/";
    GENERIC_TOKEN_ENDPOINT = "${cfg.authentik.url}/application/o/token/";
    GENERIC_USERINFO_ENDPOINT = "${cfg.authentik.url}/application/o/userinfo/";
    GENERIC_SCOPE = "openid email profile";
    GENERIC_CLIENT_USE_PKCE = "true";
    # Python dict literal (upstream parses it with ast.literal_eval).
    GENERIC_ROLE_MAPPINGS_ROLES = ''{"proxy_admin": ["${cfg.authentik.adminGroup}"]}'';
    GENERIC_ROLE_MAPPINGS_GROUP_CLAIM = "groups";
    GENERIC_ROLE_MAPPINGS_DEFAULT_ROLE = "internal_user_viewer";
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = homelabCfg.services.podman.enable;
        message = "LiteLLM runs as a Podman container: enable homelab.services.podman.";
      }
      {
        assertion = lib.all (t: backendOf ? ${t}) (lib.attrValues cfg.aliases);
        message = "homelab.services.litellm.aliases must point at models some backend serves.";
      }
      {
        assertion = lib.all (n: backendOf ? ${n} || cfg.aliases ? ${n}) (lib.attrNames cfg.fallbacks ++ lib.concatLists (lib.attrValues cfg.fallbacks));
        message = "homelab.services.litellm.fallbacks may only name served models or aliases.";
      }
    ];

    virtualisation = {
      oci-containers = {
        containers = {
          litellm = {
            inherit (cfg) image;
            autoStart = true;

            volumes = [
              "${configFile}:/app/config.yaml:ro"
            ];

            environment =
              {
                LITELLM_LOG = "INFO";
              }
              // authentikEnv;

            environmentFiles = [
              cfg.environmentFile
            ];

            cmd = [
              "--config"
              "/app/config.yaml"
              "--host"
              "127.0.0.1"
              "--port"
              (toString cfg.listenPort)
            ];

            extraOptions = [
              "--network=host"
            ];
          };
        };
      };
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.listenPort} {
                # Stream tokens as they come (SSE).
                flush_interval -1
              }
            '';
          };
        };
      };
    };
  };
}
