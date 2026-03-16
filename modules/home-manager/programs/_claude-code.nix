{homelabCfg, ...}: {
  programs = {
    claude-code = {
      inherit (homelabCfg.programs.claude-code) enable;
    };
  };
}
