# litellm-mcp — Claude Code, OpenCode and Pi use the MCP servers LiteLLM's
# gateway offers, instead of running their own.
#
# The servers run on the gateway host (machines/mentat/_mcp.nix) with their
# credentials there; a client only holds its LiteLLM virtual key, and the key
# decides which servers and tools it reaches. Each tool has its own key, so
# either can be revoked on its own:
#
#   * Claude Code: litellm.claudeCodeKeyFile, sent by a headersHelper that
#     reads the file at connect time.
#   * OpenCode: its existing gateway key (programs.opencode.litellm), read
#     through OpenCode's {file:} substitution.
#   * Pi: its gateway key (programs.pi.litellm), read by a "!command" header
#     value Pi evaluates at connect time (built-in MCP support, mcp.json).
#
# Neither key enters the Nix store or a generated config.
#
# One connection per bundle, not one for the whole catalog: the gateway's
# homelab.mcp.bundles (machines/mentat/_mcp.nix) is split into a client
# connection each, at https://<webDomain>/mcp/<servers> — LiteLLM's documented
# per-server selection (docs.litellm.ai/docs/mcp_config_reference, endpoint
# matrix), which narrows what the key reaches and never grants more. Connecting
# or disconnecting one bundle in the client's /mcp menu therefore no longer
# moves every other server, and a read-only task doesn't load the Home
# Assistant tools it will not use. programs.litellm-mcp.bundles names the
# bundles to offer (null offers all of them).
{
  homelabCfg,
  lib,
  outputs,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.litellm-mcp;
  opencodeKey = homelabCfg.programs.opencode.litellm.apiKeyFile;
  piKey = homelabCfg.programs.pi.litellm.apiKeyFile;
  gateway = outputs.nixosConfigurations.${cfg.host}.config.homelab.services.litellm;
  # The gateway's catalog: bundle name -> server names and their descriptions.
  catalog = outputs.nixosConfigurations.${cfg.host}.config.homelab.mcp.bundles;

  bundleNames =
    if cfg.bundles == null
    then builtins.attrNames catalog
    else cfg.bundles;

  # Bundle name -> { url, description }, in a stable order so a generated
  # config does not shuffle when a bundle is added.
  bundles = lib.listToAttrs (map (name: {
    inherit name;
    value = {
      # A comma-separated list of server names is one bundle endpoint.
      url = "https://${gateway.webDomain}/mcp/" + lib.concatStringsSep "," (lib.sort (a: b: a < b) catalog.${name});
      description = lib.concatStringsSep "; " (map (s: gateway.mcpServers.${s}.description) (lib.sort (a: b: a < b) catalog.${name}));
    };
  }) (lib.sort (a: b: a < b) bundleNames));

  headersHelper = name: keyFile:
    pkgs.writeShellApplication {
      name = "litellm-mcp-headers-${name}";
      runtimeInputs = [pkgs.jq];
      text = ''
        jq -cn --rawfile key ${lib.escapeShellArg keyFile} \
          '{"x-litellm-api-key": ("Bearer " + ($key | rtrimstr("\n")))}'
      '';
    };
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (b: catalog ? ${b}) bundleNames;
        message = "programs.litellm-mcp.bundles names no bundle on the gateway host ${cfg.host} (its homelab.mcp.bundles defines: ${lib.concatStringsSep ", " (builtins.attrNames catalog)}).";
      }
    ];

    programs = {
      claude-code = lib.mkIf (cfg.claudeCodeKeyFile != null) {
        mcpServers =
          lib.mapAttrs (name: b: {
            type = "http";
            inherit (b) url;
            headersHelper = lib.getExe (headersHelper name cfg.claudeCodeKeyFile);
          })
          bundles;
      };

      opencode = lib.mkIf (opencodeKey != null) {
        settings = {
          mcp =
            lib.mapAttrs (name: b: {
              type = "remote";
              inherit (b) url;
              headers = {
                "x-litellm-api-key" = "Bearer {file:${opencodeKey}}";
              };
            })
            bundles;
        };
      };
    };

    # Pi has built-in MCP support read from ~/.pi/agent/mcp.json (models.json
    # is written by _pi.nix). A "!command" header value must make up the whole
    # value, so echo supplies the Bearer prefix around the key it cats, and
    # the key stays out of the store and out of the file.
    home.file.".pi/agent/mcp.json" = lib.mkIf (piKey != null) {
      text = builtins.toJSON {
        mcpServers =
          lib.mapAttrs (name: b: {
            inherit (b) url description;
            headers = {
              "x-litellm-api-key" = "!echo Bearer $(cat ${piKey})";
            };
          })
          bundles;
      };
    };
  };
}
