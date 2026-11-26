# litellm-mcp — Claude Code and OpenCode use the MCP servers LiteLLM's
# gateway offers (https://<litellm webDomain>/mcp), instead of running their
# own.
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
#
# Neither key enters the Nix store or a generated config.
{
  homelabCfg,
  lib,
  outputs,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.litellm-mcp;
  opencodeKey = homelabCfg.programs.opencode.litellm.apiKeyFile;
  gateway = outputs.nixosConfigurations.${cfg.host}.config.homelab.services.litellm;
  url = "https://${gateway.webDomain}/mcp";

  claudeCodeHeaders = pkgs.writeShellApplication {
    name = "litellm-mcp-headers";
    runtimeInputs = [pkgs.jq];
    text = ''
      jq -cn --rawfile key ${lib.escapeShellArg cfg.claudeCodeKeyFile} \
        '{"x-litellm-api-key": ("Bearer " + ($key | rtrimstr("\n")))}'
    '';
  };
in {
  config = lib.mkIf cfg.enable {
    programs = {
      claude-code = lib.mkIf (cfg.claudeCodeKeyFile != null) {
        mcpServers = {
          litellm = {
            type = "http";
            inherit url;
            headersHelper = lib.getExe claudeCodeHeaders;
          };
        };
      };

      opencode = lib.mkIf (opencodeKey != null) {
        settings = {
          mcp = {
            litellm = {
              type = "remote";
              inherit url;
              headers = {
                "x-litellm-api-key" = "Bearer {file:${opencodeKey}}";
              };
            };
          };
        };
      };
    };
  };
}
