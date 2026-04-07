# opencode — AI coding assistant managed through Home Manager's native module.
{
  homelabCfg,
  lib,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.opencode.enable {
    programs.opencode = {
      enable = true;

      # Keep opencode on the upstream HM module and only layer in the shared
      # MCP registry so assistant server definitions stay centralized in
      # `_mcp.nix`.
      enableMcpIntegration = true;
    };
  };
}
