{
  homelabCfg,
  lib,
  ...
}: {
  programs = {
    zsh = {
      inherit (homelabCfg.programs.zsh) enable;

      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initContent = lib.mkOrder 500 ''
        if [[ "$TERM" == "dumb" ]]
        then
          unsetopt zle
          unsetopt prompt_cr
          unsetopt prompt_subst

          if whence -w precmd >/dev/null; then
            unfunction precmd
          fi

          if whence -w preexec >/dev/null; then
            unfunction preexec
          fi

          PS1='$ '
          return
        fi

        [[ -o interactive ]] || return
      '';
    };
  };
}
