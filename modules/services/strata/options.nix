# Options — Strata local LLM inference server.
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        strata = {
          enable = lib.mkEnableOption "Strata local LLM inference server.";

          stateDir = lib.mkOption {
            type = lib.types.path;
            default = "/var/lib/strata";
            description = ''
              Home directory of the strata user. Upstream's terminal, engine
              components, run configs, profiles, and logs live under its XDG
              paths here.
            '';
          };

          dataDir = lib.mkOption {
            type = lib.types.path;
            default = "/srv/models/strata-data";
            description = "Model, pack, and MTP draft-layer storage (passed as --data-dir).";
          };

          family = lib.mkOption {
            type = lib.types.str;
            default = "qwen";
            description = "Model family passed to `strata launch --family`.";
          };

          model = lib.mkOption {
            type = lib.types.str;
            default = "iq3_xxs";
            description = "Model size passed to `strata launch --model`.";
          };

          context = lib.mkOption {
            type = lib.types.str;
            default = "128k";
            description = "Context size passed to `strata launch --context`.";
          };

          vision = lib.mkOption {
            type = lib.types.enum ["off" "on" "gpu" "cpu"];
            default = "cpu";
            description = "Picture reader placement passed to `strata launch --vision`.";
          };

          mtp = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Whether to load the MTP draft layer.";
          };

          extraLaunchArgs = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Additional `strata launch` arguments used when generating the run config.";
          };

          listenAddress = lib.mkOption {
            type = lib.types.str;
            default = "127.0.0.1";
            description = "Address on which the OpenAI-compatible API listens.";
          };

          listenPort = lib.mkOption {
            type = lib.types.port;
            default = 8916;
            description = "Port on which the OpenAI-compatible API listens.";
          };

          webDomain = lib.mkOption {
            type = lib.types.str;
            default = "ai.${config.networking.domain}";
            description = ''
              Hostname Caddy serves the API on. Backend-neutral so clients keep
              the same endpoint if the inference server changes.
            '';
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3016;
            description = "UID for the Strata service user.";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3016;
            description = "GID for the Strata service group.";
          };
        };
      };
    };
  };
}
