# Shared MCP server registry for AI coding assistants.
#
# Architecture
# ------------
#   - The natsukium/mcp-servers-nix Home Manager bridge module (imported once
#     in `../home.nix`) reads any `mcp-servers.programs.<name>.enable = true;`
#     declared below and translates it into a corresponding entry under
#     `programs.mcp.servers`.
#   - Manual server entries (e.g. the local `nixos` MCP backed by `mcp-nixos`)
#     are written directly into `programs.mcp.servers`. Both sources contribute
#     keys to the same attrset and the module system merges them.
#   - Downstream assistant modules (`_claude-code.nix`, `_codex-cli.nix`,
#     `_opencode.nix`) all read `config.programs.mcp.servers`, so adding a
#     server here automatically reaches every enabled assistant — no per-tool
#     duplication.
#
# Gating
# ------
# The entire `config` block is wrapped in `lib.mkIf anyAiToolEnabled`, so on
# machines that don't enable any AI tool (typically servers) the bridge stays
# dormant, no `mcp.json` is written, and neither `mcp-nixos` nor `context7-mcp`
# enters the build closure. The `lib.getExe` lookup below is held in a `let`
# binding so lazy evaluation only forces it inside the gated branch.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  claudeCodeEnabled = homelabCfg.programs.claude-code.enable or false;
  codexEnabled = homelabCfg.programs.codex-cli.enable or false;
  opencodeEnabled = homelabCfg.programs.opencode.enable or false;
  anyAiToolEnabled = claudeCodeEnabled || codexEnabled || opencodeEnabled;
  mcpNixosExe = lib.getExe pkgs.mcp-nixos;
in {
  config = lib.mkIf anyAiToolEnabled {
    # The outer `lib.mkIf` is the real gate; this assignment exists so a
    # machine can opt out with `programs.mcp.enable = lib.mkForce false;`
    # without having to disable AI tooling entirely. `mkDefault` keeps that
    # escape hatch open.
    programs.mcp.enable = lib.mkDefault true;

    # Declarative MCP servers contributed via natsukium/mcp-servers-nix.
    # Each entry is evaluated by the bridge module and lands in
    # `programs.mcp.servers.<name>` below.
    mcp-servers.programs = {
      context7 = {
        enable = true;
      };
    };

    # Manual server entries. Currently just the local `nixos` MCP — the stdio
    # transport is set explicitly so Claude Code can reuse the entry without
    # reshaping it. Coexists with bridge-emitted entries via attrset merge.
    programs.mcp.servers = {
      nixos = {
        type = "stdio";
        command = mcpNixosExe;
      };
    };
  };
}
