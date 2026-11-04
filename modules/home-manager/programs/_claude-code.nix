# Claude Code — Anthropic's CLI coding assistant (from numtide/llm-agents.nix)
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.claude-code.enable {
    programs = {
      claude-code = {
        enable = true;
        # llm-agents builds this daily against its own pinned nixpkgs and pushes
        # the result to cache.numtide.com, so it substitutes instead of
        # recompiling against our nixpkgs (its overlay would rebuild).
        package = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code;
      };
    };
  };
}
