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

          sizes = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = lib.unique ([strataCfg.model] ++ strataCfg.models);
            defaultText = lib.literalExpression "Strata's model plus models";
            description = "Strata sizes the catalog offers.";
          };
        };
      };
    };
  };
}
