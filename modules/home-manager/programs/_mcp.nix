# Shared MCP config for coding assistants.
# Enable Home Manager's MCP config support when any assistant that consumes the
# shared registry (Claude Code, Codex CLI, opencode) is enabled so a single
# mcp.json can be managed centrally.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  claudeCodeEnabled = homelabCfg.programs.claude-code.enable or false;
  codexEnabled = homelabCfg.programs.codex-cli.enable or false;
  opencodeEnabled = homelabCfg.programs.opencode.enable or false;
  mcpNixosExe = lib.getExe pkgs.mcp-nixos;
in {
  config = {
    # Any assistant consuming the shared MCP registry should participate in the
    # gate so `mcp.json` exists whenever one of them is enabled.
    programs.mcp.enable = lib.mkDefault (claudeCodeEnabled || codexEnabled || opencodeEnabled);

    # Keep the canonical server definition in one place and expose the stdio
    # transport explicitly so Claude Code can reuse it without reshaping.
    programs.mcp.servers = {
      nixos = {
        type = "stdio";
        command = mcpNixosExe;
      };
    };
  };
}
