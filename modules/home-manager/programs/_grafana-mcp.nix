# grafana-mcp — read-only access to the fleet's logs, metrics and alerts for
# AI agents, through Grafana's MCP server (mcp-grafana) instead of SSH.
#
# Grafana on the monitoring host already fronts Loki (logs) and Prometheus
# (metrics) and holds the alert rules and dashboards, so one server gives an
# agent the whole fleet. It runs locally over stdio and reaches Grafana over
# HTTPS with a service account token, which it reads from the sops file
# itself, so the token never enters the Nix store or the generated configs.
# It is registered once in programs.mcp and shared with Claude Code and
# OpenCode.
#
# Read-only twice over: the service account has the Viewer role, and the
# server only registers read tools. --disable-write drops create/update
# tools, --disable-api drops the raw Grafana API passthrough (which would
# bypass the tool limits), and only the categories needed to look at the
# fleet are enabled. The query guardrails reject queries an agent writes
# that would scan too much (Loki: 24h and 100 GiB, Prometheus: 8 days and
# 11,000 points per series, the upstream defaults), with a hint to narrow
# them, instead of running them against heartbeat.
#
# Package: from nixpkgs-unstable (2.2.0). nixos-26.05 has 0.14.0, which can't
# read the token from a file and has no guardrails. Drop the override once
# stable carries 2.x.
{
  homelabCfg,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.grafana-mcp;
  grafana = outputs.nixosConfigurations.${cfg.host}.config.homelab.services.grafana;
  mcpGrafana = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.mcp-grafana;
in {
  config = lib.mkIf (cfg.enable && cfg.tokenFile != null) {
    programs = {
      mcp = {
        enable = true;

        servers = {
          grafana = {
            command = lib.getExe mcpGrafana;
            args = [
              "-t"
              "stdio"
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
              # 2.x reports anonymous usage statistics to Grafana Labs by
              # default; nothing about the fleet leaves the network.
              "--usage-stats"
              "disabled"
            ];
            env = {
              GRAFANA_URL = "https://${grafana.webDomain}";
              GRAFANA_SERVICE_ACCOUNT_TOKEN_FILE = cfg.tokenFile;
            };
          };
        };
      };

      claude-code = {
        enableMcpIntegration = true;
      };

      opencode = {
        enableMcpIntegration = true;
      };
    };
  };
}
