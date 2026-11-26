# MCP servers behind LiteLLM's MCP gateway.
#
# Each server runs here as its own locked-down service on loopback, speaking
# Streamable HTTP, and LiteLLM (host networking) registers it and offers it
# at https://<litellm webDomain>/mcp. Clients (Claude Code, OpenCode,
# Hermes, Open WebUI) authenticate with their own LiteLLM virtual key, and a
# key reaches a server only once it is granted it, so access is per client
# and revocable in one place. The servers' own credentials stay on mentat.
#
#   grafana: read-only fleet logs, metrics and alerts (mcp-grafana).
#     The service account has the Viewer role, and the server only registers
#     read tools: --disable-write drops create/update tools, --disable-api the
#     raw API passthrough that would bypass the tool limits. The query
#     guardrails reject queries that would scan too much (Loki: 24h and
#     100 GiB, Prometheus: 8 days and 11,000 points per series, the upstream
#     defaults). Usage reporting to Grafana Labs, on by default in 2.x, is off.
#     The package comes from nixpkgs-unstable: nixos-26.05 has 0.14.0, which
#     can't read the token from a file and has no guardrails.
#
#   nixos: NixOS, Home Manager and nix-darwin option and package lookup,
#     package version history (mcp-nixos). It holds no credentials; it
#     queries public sources (search.nixos.org, the Home Manager and
#     nix-darwin option docs, NixHub, FlakeHub), so search terms leave the
#     network, nothing else. From its own flake (the mcp-nixos input), which
#     is ahead of nixpkgs.
#
#   homeassistant / homeassistant_admin: Home Assistant (ha-mcp), one
#     service registered twice. homeassistant is ha-mcp's /readonly endpoint,
#     which hides and blocks every write tool on that connection: states,
#     history, logs, automation traces and configs. homeassistant_admin is the
#     full endpoint, which can also create and change automations, scripts,
#     dashboards and helpers and restore backups; grant it only to the keys
#     that should change Home Assistant. Both act as one admin HA user, whose
#     token reaches the service through an env file (ha-mcp reads it only from
#     the environment). The settings web UI is off. From nixpkgs-unstable
#     (stable lags at 7.x).
#
#   github: GitHub, read-only (GitHub's hosted MCP server, not a service
#     here). Its HTTP mode takes the token on every request, so it would pass
#     through LiteLLM either way, and the hosted one is always the latest
#     (nixpkgs lags at 1.14). Read-only three times over: the /readonly
#     endpoint, a fixed list of toolsets, and a fine-grained token with only
#     read permissions. Lockdown mode hides public issue and comment content
#     from users without push access, which narrows prompt injection through
#     the public repo. The token is LiteLLM's GITHUB_MCP_TOKEN, from sops.
#
# Loopback has no other gate: anything on mentat could call a server
# directly, which is acceptable while mentat runs only DNS, LiteLLM and the
# wake proxy. That matters most for homeassistant_admin, whose endpoint has
# no gate but the LiteLLM grant.
{
  config,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}: let
  cfg = config.homelab.mcp;
  grafana = outputs.nixosConfigurations.heartbeat.config.homelab.services.grafana;
  mcpGrafana = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mcp-grafana;
  mcpNixos = inputs.mcp-nixos.packages.${pkgs.stdenv.hostPlatform.system}.mcp-nixos;
  haMcp = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ha-mcp;
  homeAssistant = outputs.nixosConfigurations.heartbeat.config.homelab.services.home-assistant;
  haEndpoint = "http://127.0.0.1:${toString cfg.homeassistant.port}/mcp";

  # Shared lockdown for the servers: no privileges, read-only system, network
  # only.
  hardening = {
    DynamicUser = true;
    CapabilityBoundingSet = [""];
    RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
    NoNewPrivileges = true;
    PrivateDevices = true;
    PrivateTmp = true;
    ProtectHome = true;
    ProtectSystem = "strict";
    ProtectKernelTunables = true;
    ProtectKernelModules = true;
    ProtectControlGroups = true;
    LockPersonality = true;
    MemoryDenyWriteExecute = true;
    RestrictNamespaces = true;
    RestrictRealtime = true;
    SystemCallArchitectures = "native";
  };
in {
  options = {
    homelab = {
      mcp = {
        grafana = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 8927;
            description = "Loopback port of the Grafana MCP server (docs/service-registry.org).";
          };
        };

        nixos = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 8928;
            description = "Loopback port of the NixOS MCP server (docs/service-registry.org).";
          };
        };

        homeassistant = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 8929;
            description = "Loopback port of the Home Assistant MCP server (docs/service-registry.org).";
          };
        };
      };
    };
  };

  config = {
    homelab = {
      services = {
        litellm = {
          mcpServers = {
            grafana = {
              url = "http://127.0.0.1:${toString cfg.grafana.port}/mcp";
              description = "Read-only logs (Loki), metrics (Prometheus), alert rules and dashboards of the homelab fleet, from Grafana.";
            };
            nixos = {
              url = "http://127.0.0.1:${toString cfg.nixos.port}/mcp";
              description = "NixOS, Home Manager and nix-darwin options, nixpkgs packages and their version history.";
            };
            homeassistant = {
              url = "${haEndpoint}/readonly";
              description = "Home Assistant, read-only: entity states, history, logs, automation traces and configuration.";
            };
            github = {
              url = "https://api.githubcopilot.com/mcp/readonly";
              description = "GitHub, read-only: repositories, files, issues, pull requests and Actions runs.";
              bearerTokenEnv = "GITHUB_MCP_TOKEN";
              headers = {
                X-MCP-Toolsets = "context,repos,issues,pull_requests,actions";
                X-MCP-Readonly = "true";
                X-MCP-Lockdown = "true";
              };
            };
            homeassistant_admin = {
              url = haEndpoint;
              description = "Home Assistant with write access: also creates and changes automations, scripts, dashboards and helpers, and restores backups.";
            };
          };
        };
      };
    };

    systemd = {
      services = {
        mcp-grafana = {
          description = "Grafana MCP server (read-only) for LiteLLM's MCP gateway";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];

          environment = {
            GRAFANA_URL = "https://${grafana.webDomain}";
            # %d is the credentials directory LoadCredential fills.
            GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE = "%d/grafana-token";
          };

          serviceConfig =
            hardening
            // {
              ExecStart = lib.escapeShellArgs [
                (lib.getExe mcpGrafana)
                "-t"
                "streamable-http"
                "--address"
                "127.0.0.1:${toString cfg.grafana.port}"
                "--enabled-tools"
                (lib.concatStringsSep "," [
                  "search"
                  "datasource"
                  "prometheus"
                  "loki"
                  "alerting"
                  "dashboard"
                  "folder"
                  "annotations"
                  "navigation"
                ])
                "--disable-write"
                "--disable-api"
                "--loki-guardrail-mode"
                "enforce"
                "--prometheus-guardrail-mode"
                "enforce"
                "--usage-stats"
                "disabled"
              ];
              LoadCredential = ["grafana-token:${config.sops.secrets."grafana/mcp-token".path}"];
              Restart = "always";
              RestartSec = 5;
            };
        };

        mcp-nixos = {
          description = "NixOS MCP server (option and package lookup) for LiteLLM's MCP gateway";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];

          environment = {
            MCP_NIXOS_TRANSPORT = "http";
            MCP_NIXOS_HOST = "127.0.0.1";
            MCP_NIXOS_PORT = toString cfg.nixos.port;
            # LiteLLM keeps no MCP session between requests.
            MCP_NIXOS_STATELESS_HTTP = "1";
            # Lookup caches, in the service's own cache directory.
            HOME = "/var/cache/mcp-nixos";
            XDG_CACHE_HOME = "/var/cache/mcp-nixos";
          };

          serviceConfig =
            hardening
            // {
              ExecStart = lib.getExe mcpNixos;
              CacheDirectory = "mcp-nixos";
              Restart = "always";
              RestartSec = 5;
            };
        };

        mcp-homeassistant = {
          description = "Home Assistant MCP server (ha-mcp) for LiteLLM's MCP gateway";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];

          environment = {
            HOMEASSISTANT_URL = "https://${homeAssistant.webDomain}";
            MCP_HOST = "127.0.0.1";
            MCP_PORT = toString cfg.homeassistant.port;
            MCP_SECRET_PATH = "/mcp";
            HA_MCP_DISABLE_SETTINGS_UI = "1";
            # Edit backups and settings, in the service's own state directory.
            HOME = "/var/lib/mcp-homeassistant";
            XDG_DATA_HOME = "/var/lib/mcp-homeassistant";
            XDG_CONFIG_HOME = "/var/lib/mcp-homeassistant";
            XDG_CACHE_HOME = "/var/lib/mcp-homeassistant/cache";
          };

          serviceConfig =
            hardening
            // {
              ExecStart = lib.getExe' haMcp "ha-mcp-web";
              EnvironmentFile = config.sops.templates."ha-mcp.env".path;
              StateDirectory = "mcp-homeassistant";
              Restart = "always";
              RestartSec = 5;
            };
        };
      };
    };
  };
}
