# Codex CLI — OpenAI's CLI coding assistant (from sadjow/codex-cli-nix)
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf homelabCfg.programs.codex-cli.enable {
    home = {
      packages = with pkgs; [
        bubblewrap # Sandbox runtime required by Codex CLI
        codex # Native binary (hourly updates from sadjow/codex-cli-nix)
      ];
    };
  };
}
