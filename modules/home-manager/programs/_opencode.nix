# opencode — AI coding assistant managed through Home Manager's native module
# (package from numtide/llm-agents.nix)
#
# Models come from the LiteLLM gateway (modules/services/litellm). OpenCode
# cannot list a custom OpenAI-compatible provider's models itself (its
# discovery only covers vLLM, LM Studio and Ollama), so the list is generated
# from the gateway host's catalog: every model and alias LiteLLM serves, with
# the context and output limits of the engine behind it. Adding a model to
# LiteLLM adds it here on the next deploy. Engines with less context than
# litellm.minContextLength are left out: heartbeat's 32K Gemma needs ~2
# minutes just for OpenCode's ~12K-token agent prompt. The opencode virtual
# key in LiteLLM must allow the listed models. litellm.maxContextLength can
# cap the context OpenCode sees below the engine's.
{
  homelabCfg,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.opencode;
  gateway = outputs.nixosConfigurations.${cfg.litellm.host}.config.homelab.services.litellm;

  # Model name -> the backend serving it, for backends with enough context
  # for an OpenCode session (see litellm.minContextLength).
  backendOf = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (
      _: b: map (m: lib.nameValuePair m b) b.models
    )
    (lib.filterAttrs (_: b: b.contextLength >= cfg.litellm.minContextLength) gateway.backends)));

  # Aliases whose target survived the filter.
  aliases = lib.filterAttrs (_: target: backendOf ? ${target}) gateway.aliases;

  # litellm.maxContextLength caps what OpenCode is told, not what the engine
  # serves: OpenCode compacts against this limit.
  contextOf = backend:
    if cfg.litellm.maxContextLength == null
    then backend.contextLength
    else lib.min backend.contextLength cfg.litellm.maxContextLength;

  entry = label: backend: {
    name = label;
    limit = {
      context = contextOf backend;
      output = backend.maxOutputTokens;
    };
  };

  models =
    lib.mapAttrs (name: backend: entry name backend) backendOf
    // lib.mapAttrs (alias: target: entry "${alias} (${target})" backendOf.${target}) aliases;

  defaultModel =
    if models ? heavy
    then "heavy"
    else lib.head (lib.attrNames models);
in {
  config = lib.mkIf cfg.enable {
    programs = {
      opencode = {
        enable = true;

        # OpenCode 2, not llm-agents' v1 `opencode`: the existing config and
        # data under ~/.config/opencode and ~/.local/share/opencode are in v2
        # format, which v1 cannot read. llm-agents builds it daily against its
        # own pinned nixpkgs and pushes it to cache.numtide.com, so it
        # substitutes instead of recompiling. It installs the binary as
        # bin/opencode2 so it can coexist with v1; the symlinkJoin only adds an
        # `opencode` link to it, keeping the usual command name and giving the
        # HM module's wrappers (which call bin/opencode) a target. The
        # symlinkJoin builds locally in seconds; opencode2 itself still
        # substitutes, since nothing overrides it.
        package = let
          opencode2 = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2;
        in
          pkgs.symlinkJoin {
            name = "opencode2-${opencode2.version}";
            inherit (opencode2) version;
            paths = [
              opencode2
            ];
            postBuild = ''
              ln -s $out/bin/opencode2 $out/bin/opencode
            '';
            meta =
              opencode2.meta
              // {
                mainProgram = "opencode";
              };
          };

        # The output limits come from the gateway's backends. For Qwen it is
        # 32768: it thinks, so reasoning counts against the cap, and at 4096
        # compacting a ~225K session spent the budget before finishing the
        # summary. OpenCode reserves the output limit out of the context when
        # deciding when to compact.
        settings =
          {
            "$schema" = "https://opencode.ai/config.json";

            # No subagents. Strata serves one request at a time, so a
            # subagent never runs alongside the main agent; it only waits its
            # turn, reads its own ~12K-token prompt from scratch, and evicts
            # the main session's cache on the way. Denying the task tool stops
            # the main agent from starting any, including ones added later;
            # the built-in explore and general are disabled outright.
            permission = {
              task = "deny";
            };
            # Compact only when it is due, as a step in the session. By default
            # opencode also summarizes the whole session in the background as
            # it nears the limit (session/compaction.ts, v2.4.1), a hidden job
            # of up to ~96K tokens that holds Strata's single slot while the
            # next turn waits behind it. Automatic compaction stays on.
            compaction = {
              background = false;
            };

            agent = {
              explore = {
                disable = true;
              };
              general = {
                disable = true;
              };
            };
          }
          // lib.optionalAttrs (cfg.litellm.apiKeyFile != null) {
            model = "litellm/${defaultModel}";
          }
          # Session titles are a short prompt and a few words back, so they go
          # to heartbeat's small agent model instead of heavy: no waiting on
          # ixian's single slot, and no waking it from suspend for a title.
          // lib.optionalAttrs (cfg.litellm.apiKeyFile != null && models ? agent) {
            small_model = "litellm/agent";
          }
          // lib.optionalAttrs (cfg.litellm.apiKeyFile != null) {
            provider = {
              litellm = {
                npm = "@ai-sdk/openai-compatible";
                name = "LiteLLM";
                options = {
                  baseURL = "https://${gateway.webDomain}/v1";
                  apiKey = "{file:${cfg.litellm.apiKeyFile}}";
                };
                inherit models;
              };
            };
          };
      };
    };
  };
}
