# Zsh — primary interactive shell with autosuggestion and syntax highlighting.
# Includes a dumb-terminal guard (for Emacs TRAMP) and optional local overrides.
{
  homelabCfg,
  lib,
  ...
}: {
  programs = {
    zsh = {
      inherit (homelabCfg.programs.zsh) enable;

      autosuggestion = {
        enable = true;
      };

      syntaxHighlighting = {
        enable = true;
      };

      # Dumb terminal guard — disable ZLE and fancy prompts for TRAMP/scp
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

      profileExtra = ''
        # Optional local overrides (not managed by nix)
        if [ -f "$HOME/.local.zprofile" ]; then
          source "$HOME/.local.zprofile"
        fi
      '';
    };
  };
}
