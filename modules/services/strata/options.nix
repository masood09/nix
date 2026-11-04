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

          parallel = lib.mkOption {
            type = lib.types.ints.between 1 8;
            default = 1;
            description = ''
              Requests answered at the same time, passed as `--parallel` to both
              `strata launch` and `strata serve`. Each slot holds its own
              conversation memory of `context` tokens, so N slots cost N times
              the cache and leave less graphics memory for experts.
            '';
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

          tvGuard = {
            enable = lib.mkEnableOption ''
              stopping Strata while an Android TV is on, freeing VRAM and RAM
              for games. Enabling it also makes the guard the only thing that
              starts Strata: strata.service is left out of multi-user.target, so
              neither boot nor a switch loads the model while the TV has the
              GPU. The TV is polled over network ADB, and Strata starts once the
              TV has been off (unreachable) for offDelay seconds, including the
              first time after boot. A manual `systemctl stop strata` is
              respected until the next TV on -> off cycle, or until a manual
              `systemctl start strata`.
            '';

            address = lib.mkOption {
              type = lib.types.str;
              example = "tv.example.lan:5555";
              description = ''
                host:port of the TV's network ADB. The TV must allow this host's
                ADB key once (an "Allow USB debugging?" prompt on screen).
              '';
            };

            interval = lib.mkOption {
              type = lib.types.ints.positive;
              default = 10;
              description = "Seconds between TV power checks.";
            };

            offDelay = lib.mkOption {
              type = lib.types.ints.unsigned;
              default = 30;
              description = "Seconds the TV must stay off before Strata is started again.";
            };
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
