# Qwen Code — Qwen3-Coder terminal coding CLI (from numtide/llm-agents.nix)
#
# Home Manager release-26.05 has no `programs.qwen-code` module (its AI CLI
# modules are only claude-code, codex, gemini-cli and opencode), so install the
# input's package through `home.packages` instead of a native program module.
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.qwen-code.enable {
    home = {
      packages = [
        # llm-agents builds this daily against its own pinned nixpkgs and pushes
        # the result to cache.numtide.com, so it substitutes instead of
        # recompiling against our nixpkgs (its overlay would rebuild).
        inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.qwen-code
      ];
    };
  };
}
