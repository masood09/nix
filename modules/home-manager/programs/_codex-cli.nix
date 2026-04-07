# Codex CLI — OpenAI's CLI coding assistant (from sadjow/codex-cli-nix)
{
  config,
  homelabCfg,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.codex-cli.enable {
    programs.codex = {
      enable = true;
      package = pkgs.codex;

      # Keep Codex on the upstream HM module while layering in local defaults
      # and the shared MCP server registry managed by `_mcp.nix`.
      settings =
        {
          tui = {
            theme = "gruvbox-dark";
          };
        }
        // lib.optionalAttrs (config.programs.mcp.servers != {}) {
          mcp_servers = lib.mkDefault config.programs.mcp.servers;
        };
    };

    home = {
      packages = with pkgs; [
        bubblewrap # Sandbox runtime required by Codex CLI
      ];
    };
  };
}
