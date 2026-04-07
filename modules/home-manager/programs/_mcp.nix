# Shared MCP config for coding assistants.
# Enable Home Manager's MCP config support when either Claude Code or Codex CLI
# is enabled so a single mcp.json can be managed centrally.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  claudeCodeEnabled = homelabCfg.programs.claude-code.enable or false;
  codexEnabled = homelabCfg.programs.codex-cli.enable or false;
  mcpNixosExe = lib.getExe pkgs.mcp-nixos;
in {
  config = {
    programs.mcp.enable = lib.mkDefault (claudeCodeEnabled || codexEnabled);

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
