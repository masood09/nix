# Claude Code — Anthropic's CLI coding assistant (from sadjow/claude-code-nix)
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
        # Input's prebuilt package (built against claude-code-nix's own nixpkgs)
        # so it resolves from claude-code.cachix.org instead of recompiling. The
        # overlay path (pkgs.claude-code) would rebuild against our nixpkgs.
        package = inputs.claude-code.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };
    };
  };
}
