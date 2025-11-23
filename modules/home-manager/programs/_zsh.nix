{
  homelabCfg,
  pkgs,
  ...
}: {
  programs = {
    zsh = {
      inherit (homelabCfg.programs.zsh) enable;

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      plugins = [
        {
          name = "vi-mode";
          src = pkgs.zsh-vi-mode;
          file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
        }
      ];
    };
  };
}
