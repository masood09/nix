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
            description = ''
              Model size passed to `strata launch --model`: the size served
              when nothing else is selected.
            '';
          };

          models = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            example = ["iq2_xs" "iq3_xxs" "iq3_s"];
            description = ''
              Additional sizes Strata may be switched to at runtime (the
              default `model` is always included). Each size keeps its own
              generated run config, so switching to a generated size costs one
              model load. Every start regenerates whichever sizes are stale
              (after a deploy that changes launch options, or an update), one
              extra model load per stale size, so later switches stay one load.
            '';
          };

          selectionFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "/var/lib/model-router/strata-variant";
            description = ''
              File naming the size to serve, read at every start (written by a
              model switcher such as model-router). A missing file, or a size
              not in `model`/`models`, falls back to `model`.
            '';
          };

          holdFile = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "/run/console-mode/gaming";
            description = ''
              While this file exists, nothing starts Strata: strata.service and
              the update (whose test start needs the GPU) skip through an
              ExecCondition, whoever asks: boot, a switch, a manual start, a
              model switcher, or the update's own restore. Whatever creates the
              file owns the GPU meanwhile and stops Strata itself. model-router
              holds its Strata backend on the same file.
            '';
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

          experimentalSpeedProjection = lib.mkEnableOption ''
            upstream's experimental speed projection (off by default upstream):
            a 480 KB control vector, shipped with the terminal, projected out of
            layers 4-44 of the original Qwen3.8-Flash-Next. Upstream's package
            describes it as a refusal-direction projection: the model declines
            far fewer requests, so a safety behavior is removed. It also costs
            0.2-0.4% per token, and upstream measured perplexity +15% on code,
            +2.3% on a document and +0.4% on chat (on Q2_0). Once loaded it applies to
            every request; a request can opt out with
            `"experimental_speed_projection": false`. Only the qwen and coder
            families accept it. Toggling restarts Strata (one model load) but
            does not regenerate the run config'';

          settings = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
            example = {
              reasoning_effort = "medium";
              reasoning_budget_tokens = 8192;
            };
            description = ''
              Top-level keys merged into upstream's run config before every
              start (upstream's `GET /config` lists the editable ones, e.g.
              `reasoning_effort`, `reasoning_budget_tokens`, `sampling`,
              `idle_unload_s`). `strata launch` has no flag for these, and
              `--set` only reaches engine flags and STRATA_* variables. A key
              removed here is removed from the run config on the next start.
              Changing these restarts Strata but does not regenerate the run
              config, so it costs one model load, not two. Upstream validates
              the values at start and refuses to serve on a bad one.
            '';
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

          autoUpdate = {
            enable = lib.mkEnableOption ''
              a daily check of upstream's signed update feed. When a newer
              engine or terminal (Control) is offered, Strata is stopped,
              `strata update` installs it, and Strata is started again if it
              was running. A new engine is switched to only after a full test
              start of the model passes, so a failed test leaves the old one in
              place; a new Control is checked only with `--version`. An update
              costs the test start, one run-config regeneration per configured
              size on the next start, and the serve itself. Nothing keeps the
              test start off a GPU another workload (such as a game session) is
              using, so schedule it for a quiet time
            '';

            schedule = lib.mkOption {
              type = lib.types.str;
              default = "*-*-* 04:30";
              description = ''
                systemd OnCalendar expression for the update check. Missed runs
                are not caught up at boot, so an update never stops Strata
                right after boot started it.
              '';
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
