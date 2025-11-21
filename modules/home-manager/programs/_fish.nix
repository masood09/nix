{
  pkgs,
  lib,
  ...
}: {
  programs = {
    bash = {
      enable = true;
      bashrcExtra = ''
        if [[ $(${pkgs.procps}/bin/ps h -p $PPID -o comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };

    zsh = {
      enable = true;
      initContent = lib.mkOrder 500 ''
        if [[ $(${pkgs.procps}/bin/ps -p $PPID -o comm=) != "fish" ]]; then
          # Check if this is a login shell
          if [[ -o login ]]; then
            LOGIN_OPTION="--login"
          else
            LOGIN_OPTION=""
          fi

          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };

    fish = {
      enable = true;

      shellAliases = {
        cat = "bat";
        cd = "z";
        em = "emacsclient -c -n -a ''";
        ls = "eza --color=always --git --icons=always";
      };

      interactiveShellInit = ''
        # Disable greeting
        set fish_greeting

        set -x EDITOR nvim
        set -x VISUAL nvim
      '';

      plugins = [
        {
          name = "tide";
          inherit (pkgs.fishPlugins.tide) src;
        }
        {
          name = "fzf";
          inherit (pkgs.fishPlugins.fzf) src;
        }
      ];
    };
  };

  home.activation.configure-tide = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${pkgs.fish}/bin/fish -c "tide configure --auto \
      --style=Rainbow \
      --prompt_colors='True color' \
      --show_time=No \
      --rainbow_prompt_separators=Round \
      --powerline_prompt_heads=Sharp \
      --powerline_prompt_tails=Flat \
      --powerline_prompt_style='Two lines, character' \
      --prompt_connection=Disconnected \
      --powerline_right_prompt_frame=No \
      --prompt_spacing=Sparse \
      --icons='Many icons' \
      --transient=Yes" 2> /dev/null || true
  '';
}
