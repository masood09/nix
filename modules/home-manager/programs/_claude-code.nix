# Claude Code — Anthropic's CLI coding assistant.
{homelabCfg, ...}: {
  programs = {
    claude-code = {
      inherit (homelabCfg.programs.claude-code) enable;
    };
  };
}
