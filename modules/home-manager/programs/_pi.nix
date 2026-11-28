# pi — minimal coding agent (Earendil Works, from numtide/llm-agents.nix).
#
# Home Manager release-26.05 has no `programs.pi` module, so the package is
# installed through `home.packages` (llm-agents builds it daily against its
# own pinned nixpkgs and pushes it to cache.numtide.com, so it substitutes
# instead of recompiling against our nixpkgs — its overlay would rebuild) and
# Pi's files are written directly under its agent directory, ~/.pi/agent.
#
# Models come from the LiteLLM gateway (modules/services/litellm), mirroring
# _opencode.nix: the list is generated from the gateway host's catalog — every
# model and alias LiteLLM serves, with the context and output limits of the
# engine behind it — written to models.json as an OpenAI-compatible provider.
# The gateway hands models out by name, so a bare id is what the /v1 endpoint
# expects. The pi virtual key in LiteLLM must allow the listed models.
#
# The key is NOT in the generated JSON: Pi resolves a leading "!command" in
# apiKey values at request time, so models.json only names the sops secret
# path. Pi's litellm-mcp entry (mcp.json) is added by _litellm-mcp.nix.
#
# settings.json is left entirely to the user: Pi's own /model and /thinking
# Ctrl+S saves write the default model and thinking level there, and a
# declarative file would fight them on every activation. The one exception is
# the theme files (home.file below), which are data Pi reads from that
# directory — the theme key that selects one still lives in settings.json.
#
# Themes come from pkgs.oh-pi-themes (nix/pkgs/oh-pi-themes) and are linked
# into ~/.pi/agent/themes, the only directory Pi hot-reloads themes from; the
# alternative (`pi install npm:@ifi/oh-pi-themes`) runs npm at startup and
# records itself in settings.json, which is exactly what the block above avoids.
{
  homelabCfg,
  inputs,
  lib,
  outputs,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.pi;
  gateway = outputs.nixosConfigurations.${cfg.litellm.host}.config.homelab.services.litellm;

  # Model name -> the backend serving it, for backends with enough context
  # for a Pi session (see litellm.minContextLength).
  backendOf = lib.listToAttrs (lib.concatLists (lib.mapAttrsToList (
      _: b: map (m: lib.nameValuePair m b) b.models
    )
    (lib.filterAttrs (_: b: b.contextLength >= cfg.litellm.minContextLength) gateway.backends)));

  # Aliases whose target survived the filter.
  aliases = lib.filterAttrs (_: target: backendOf ? ${target}) gateway.aliases;

  # litellm.maxContextLength caps what Pi is told, not what the engine
  # serves: Pi compacts sessions against this limit.
  contextOf = backend:
    if cfg.litellm.maxContextLength == null
    then backend.contextLength
    else lib.min backend.contextLength cfg.litellm.maxContextLength;

  # Pi's schema (docs/models-configuration.md): id is the model name sent to
  # the API, contextWindow/maxTokens drive compaction and completion sizes.
  # `name` is a display name, also matched by /model and --model patterns;
  # prettify the dashed catalog names. `input` and `reasoning` come from the
  # engine's own capabilities: Pi only attaches images for a model whose
  # input lists image, and only offers /thinking for reasoning models.
  entry = label: backend: {
    id = label;
    name = lib.replaceStrings ["-"] [" "] label;
    contextWindow = contextOf backend;
    maxTokens = backend.maxOutputTokens;
    reasoning = backend.supportsReasoning;
    input = ["text"] ++ lib.optional backend.supportsVision "image";
  };

  models =
    lib.mapAttrs (name: backend: entry name backend) backendOf
    // lib.mapAttrs (alias: target: entry alias backendOf.${target}) aliases;

  defaultModel =
    if models ? heavy
    then "heavy"
    else lib.head (lib.attrNames models);

  # Pi matches a theme by its name, and its own docs require the file name to
  # match ("Use the theme name as the filename"), so the package's
  # themes/<name>.json is linked under the same name.
  themeFiles = lib.listToAttrs (map (name:
    lib.nameValuePair ".pi/agent/themes/${name}.json" {
      source = "${pkgs.oh-pi-themes}/themes/${name}.json";
    })
  cfg.themes);
in {
  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
      ];

      file =
        {
          ".pi/agent/models.json" = lib.mkIf (cfg.litellm.apiKeyFile != null) {
            text = builtins.toJSON {
              # Editor validation/completion, per Pi's models docs.
              "$schema" = "https://pi.dev/schemas/models.schema.json";

              providers.litellm = {
                baseUrl = "https://${gateway.webDomain}/v1";
                api = "openai-completions";
                # Resolved at request time (never cached), so the key stays in
                # the sops secret, out of the Nix store and out of the file.
                apiKey = "!cat ${cfg.litellm.apiKeyFile}";
                # LiteLLM authenticates with the x-litellm-api-key header like
                # every client here; sending Authorization: Bearer as well would
                # compete with it (docs/models.md: an explicit Authorization
                # overrides Pi's default OpenAI auth header).
                authHeader = false;
                models = lib.attrValues models;
              };
            };
          };
        }
        // themeFiles;
    };
  };
}
