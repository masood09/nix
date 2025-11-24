{
  homelabCfg,
  ...
}: {
  programs = {
    zsh = {
      inherit (homelabCfg.programs.zsh) enable;

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
    };
  };
}
