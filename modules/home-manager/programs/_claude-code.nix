# Claude Code — Anthropic's CLI coding assistant (from sadjow/claude-code-nix)
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.claude-code.enable {
    home = {
      packages = with pkgs; [
        claude-code # Native binary (hourly updates from sadjow/claude-code-nix)
      ];
    };
  };
}
