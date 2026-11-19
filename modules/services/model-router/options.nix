# Options — model-router in front of Strata (listen address, catalog, timeouts).
{
  config,
  lib,
  ...
}: let
  strataCfg = config.homelab.services.strata;
in {
  options = {
    homelab = {
      services = {
        model-router = {
          enable = lib.mkEnableOption ''
            model-router, the OpenAI-compatible proxy that switches Strata's
            model size per request (github.com/masood09/model-router)'';

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address model-router listens on. Loopback until a client (e.g. LiteLLM) is wired to it.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8922;
            description = "Port model-router listens on (see docs/service-registry.org).";
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3020;
            description = "UID of the model-router service user.";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3020;
            description = "GID of the model-router service group.";
          };

          namePrefix = lib.mkOption {
            type = lib.types.str;
            default = "qwen3.8-flash-next-";
            description = "Prefix of the model names: <prefix><size>, and <prefix><size><uncensoredSuffix>.";
          };

          uncensoredSuffix = lib.mkOption {
            type = lib.types.str;
            default = "-uncensored";
            description = ''
              Suffix of each size's second name, which sets
              `experimental_speed_projection: true` (the stock name sets false).
              Both names share one loaded model, so choosing between them never
              switches anything. Requires Strata's experimentalSpeedProjection.
            '';
          };

          selectionFile = lib.mkOption {
            type = lib.types.str;
            default = "/var/lib/model-router/strata-variant";
            description = "File model-router writes the selected size to; Strata reads it at start.";
          };

          maxWait = lib.mkOption {
            type = lib.types.str;
            default = "20m";
            description = "Longest a request waits for its size to be loaded.";
          };

          switchTimeout = lib.mkOption {
            type = lib.types.str;
            default = "15m";
            description = ''
              Bound on `systemctl restart strata` and on readiness after it. A
              size whose run config went stale regenerates inside the restart
              (an extra model load), so this allows for that.
            '';
          };

          startupGrace = lib.mkOption {
            type = lib.types.str;
            default = "5m";
            description = ''
              How long model-router waits for Strata when strata.service is up
              but no model is loaded, before it restarts Strata. That state is
              either a load in progress (a cold 256K load takes about 3.5 min)
              or an engine that stopped and only reloads on a request, which
              model-router never sends while waiting. At most switchTimeout.
            '';
          };

          sizes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = lib.unique ([strataCfg.model] ++ strataCfg.models);
            defaultText = lib.literalExpression "Strata's model plus models";
            description = "Strata sizes the catalog offers.";
          };

          clientTokensFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = lib.literalExpression ''config.sops.secrets."llm/backend-key".path'';
            description = ''
              File of bearer tokens (one per line, at least 16 characters)
              that clients must send. It also guards the router's metrics and
              state endpoints. Required unless listenAddress is loopback.
              Readable by the model-router user.
            '';
          };

          openFirewall = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether to open listenPort in the firewall.";
          };

          firewallInterfaces = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["tailscale0"];
            description = "Interfaces to open listenPort on. Empty means every interface.";
          };
        };
      };
    };
  };
}
