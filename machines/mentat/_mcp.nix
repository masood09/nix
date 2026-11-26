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
# Loopback has no other gate: anything on mentat could call a server
# directly, which is acceptable while mentat runs only DNS, LiteLLM and the
# wake proxy.
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

          serviceConfig = {
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
        };
      };
    };
  };
}
