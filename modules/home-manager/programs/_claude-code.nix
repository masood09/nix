# Claude Code — Anthropic's CLI coding assistant (from sadjow/claude-code-nix)
{
  config,
  homelabCfg,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.claude-code.enable {
    programs.claude-code = {
      enable = true;
      package = pkgs.claude-code;

      # Reuse the shared Home Manager MCP registry instead of maintaining a
      # separate Claude-only server list in this module.
      mcpServers = lib.mkDefault config.programs.mcp.servers;
    };
  };
}
