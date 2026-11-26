# Open WebUI — chat front end for the local LLM stack. Wraps the upstream
# nixpkgs `services.open-webui` module with a static user, an optional ZFS
# dataset, and a Caddy vhost. Authentik OIDC is the only login method, and
# every model request goes through the LiteLLM gateway on mentat.
#
# Secrets (sops `open-webui/.env`, loaded as EnvironmentFile, which systemd
# applies over Environment=): WEBUI_SECRET_KEY, OPENAI_API_KEY (LiteLLM
# virtual key), OAUTH_CLIENT_SECRET.
#
# License: nixpkgs marks open-webui non-free (license.free = false, after
# upstream's relicensing), the first non-free nixpkgs package in a service
# closure. The host's allowUnfree doesn't reach the unstable package set, so
# openWebuiPackage below allows it explicitly.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.open-webui;
  caddyEnabled = config.services.caddy.enable;

  # The pinned stable input ships 0.12.5; 0.13.x carries the OAuth and
  # config-handling behavior this module is written against (verified on
  # 0.13.3). Unlike actual/immich/karakeep this can't use
  # `inputs.nixpkgs-unstable.legacyPackages`: that instance is built without
  # our nixpkgs.config, so its unfree check rejects open-webui. Import it
  # instead, allowing only this one package.
  openWebuiPackage =
    (import inputs.nixpkgs-unstable {
      inherit (pkgs.stdenv.hostPlatform) system;
      config = {
        allowUnfreePredicate = pkg: lib.getName pkg == "open-webui";
      };
    }).open-webui;

  # LiteLLM's MCP gateway as one tool connection. No access_grants, which
  # Open WebUI treats as admin-only; the key's LiteLLM grants decide which
  # servers (Grafana, GitHub, Home Assistant read-only, NixOS, web search)
  # it carries.
  openWebuiWithMcp = pkgs.writeShellApplication {
    name = "open-webui-with-mcp";
    runtimeInputs = [pkgs.jq];
    text = ''
      TOOL_SERVER_CONNECTIONS="$(jq -cn \
        --arg url ${lib.escapeShellArg cfg.inference.mcpUrl} \
        --arg key "''${OPENAI_API_KEY:?OPENAI_API_KEY must be set in the sops .env}" \
        '[{
          type: "mcp",
          url: $url,
          path: "",
          auth_type: "bearer",
          key: $key,
          config: {enable: true},
          info: {
            id: "litellm",
            name: "LiteLLM",
            description: "Homelab tools through LiteLLM: Grafana, GitHub, Home Assistant (read-only), NixOS, web search"
          }
        }]')"
      export TOOL_SERVER_CONNECTIONS
      exec ${openWebuiPackage}/bin/open-webui "$@"
    '';
  };
  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "open-webui";
    inherit (cfg) dataDir;
    user = "open-webui";
    group = "open-webui";
    mainServices = ["open-webui"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-open-webui";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab = {
      zfs = {
        datasets = {
          open-webui = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;
            requiredBy = ["open-webui.service"];

            restic = {
              inherit (cfg.zfs.restic) enable;
            };
          };
        };
      };
    };

    services = {
      open-webui = {
        enable = true;
        package = openWebuiPackage;
        host = cfg.listenAddress;
        port = cfg.listenPort;
        stateDir = cfg.dataDir;
        environmentFile = config.sops.secrets."open-webui/.env".path;

        environment = {
          # Setting `environment` replaces upstream's default attrset, so its
          # telemetry opt-outs have to be restated here.
          SCARF_NO_ANALYTICS = "True";
          DO_NOT_TRACK = "True";
          ANONYMIZED_TELEMETRY = "False";

          # Upstream sets http://localhost:<port>; OAuth redirects and links
          # need the public URL.
          WEBUI_URL = "https://${cfg.webDomain}";

          # Nix is the source of truth. In 0.13.x this bypasses the DB config
          # table entirely, so every admin-UI setting (web search, model
          # defaults, branding, ...) reverts to env/defaults on restart. The
          # oauth.* keys are env-only either way (OAUTH_PERSISTENT_ENABLED
          # defaults to false).
          ENABLE_PERSISTENT_CONFIG = "False";

          # Inference only through LiteLLM.
          ENABLE_OLLAMA_API = "False";
          ENABLE_OPENAI_API = "True";
          OPENAI_API_BASE_URL = cfg.inference.baseUrl;

          # Authentik OIDC is the only way in; the Authentik application's
          # bindings decide who can get an account.
          ENABLE_OAUTH_SIGNUP = "True";
          OAUTH_PROVIDER_NAME = "Authentik";
          OPENID_PROVIDER_URL = cfg.oidc.providerUrl;
          OAUTH_CLIENT_ID = cfg.oidc.clientId;
          OAUTH_SCOPES = "openid email profile";
          OAUTH_MERGE_ACCOUNTS_BY_EMAIL = "True";
          ENABLE_LOGIN_FORM = "False";
          ENABLE_PASSWORD_AUTH = "False";

          # Mirror the Authentik groups claim (kids/parents/homelab-admins)
          # into Open WebUI groups at every login, creating missing ones, so
          # per-model access can be granted by group. Group membership and
          # model access live in their own tables, not the config table, so
          # ENABLE_PERSISTENT_CONFIG = False doesn't reset them.
          ENABLE_OAUTH_GROUP_MANAGEMENT = "True";
          ENABLE_OAUTH_GROUP_CREATION = "True";
          OAUTH_GROUPS_CLAIM = "groups";

          # One LiteLLM key for everyone, but every request carries
          # X-OpenWebUI-User-Email, which LiteLLM maps to an end user
          # (user_header_mappings in modules/services/litellm) for per-person
          # spend.
          ENABLE_FORWARD_USER_INFO_HEADERS = "True";

          # Upstream defaults to "pending", which would leave every new OIDC
          # user waiting for manual approval. The first user becomes admin.
          DEFAULT_USER_ROLE = "user";
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://${cfg.listenAddress}:${toString cfg.listenPort}
            '';
          };
        };
      };
    };

    users = {
      users = {
        open-webui = {
          isSystemUser = true;
          group = "open-webui";
          uid = cfg.userId;
        };
      };

      groups = {
        open-webui = {
          gid = cfg.groupId;
        };
      };
    };

    systemd = lib.mkMerge [
      permSvc.systemd
      {
        services = {
          open-webui = {
            # Static user instead of upstream's DynamicUser so the UID stays
            # stable across ZFS snapshot and restic restores; StateDirectory
            # then resolves to /var/lib/open-webui, matching dataDir.
            serviceConfig = {
              DynamicUser = lib.mkForce false;
              User = "open-webui";
              Group = "open-webui";
            };
          };
        };
      }
      (lib.mkIf (cfg.inference.mcpUrl != null) {
        services = {
          open-webui = {
            # TOOL_SERVER_CONNECTIONS is JSON that carries the key, so it is
            # built at start from the OPENAI_API_KEY the sops .env already
            # loads: the connection stays declared here, the key is not
            # stored twice, and nothing secret enters the store.
            serviceConfig = {
              ExecStart = lib.mkForce "${lib.getExe openWebuiWithMcp} serve --host ${lib.escapeShellArg cfg.listenAddress} --port ${toString cfg.listenPort}";
            };
          };
        };
      })
    ];

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [cfg.dataDir];
    };
  };
}
