{
  homelabCfg,
  pkgs,
  lib,
  ...
}: let
  fishEnabled = homelabCfg.programs.fish.enable or false;
in {
  programs = {
    bash = lib.mkIf fishEnabled {
      bashrcExtra = ''
        if [[ $(${pkgs.procps}/bin/ps h -p $PPID -o comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
        fi
      '';
    };

    zsh = lib.mkIf fishEnabled {
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
      inherit (homelabCfg.programs.fish) enable;

      interactiveShellInit = ''
        # Disable greeting
        set fish_greeting

        set -x EDITOR vi
        set -x VISUAL vi
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

  # This should be only if fishEnabled is true
  home.activation.configure-tide =
    lib.mkIf fishEnabled
    (lib.hm.dag.entryAfter ["writeBoundary"] ''
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
    '');
}
