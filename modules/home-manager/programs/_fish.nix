# Fish shell — opt-in shell with tide prompt (Stylix-themed), fzf, done
# notifications, and bang-bang history. Starship is disabled for fish (see
# _starship.nix) because tide handles the prompt instead.
{
  config,
  homelabCfg,
  pkgs,
  lib,
  ...
}: let
  # Base16 hex colors (no '#' prefix) from the active Stylix scheme — used to
  # theme every tide prompt segment so the prompt stays consistent across
  # machines even when the color scheme differs (e.g. catppuccin-mocha vs
  # sonic-dark).
  inherit (config.lib.stylix) colors;
in {
  programs = {
    fish = {
      inherit (homelabCfg.programs.fish) enable;

      interactiveShellInit = ''
        # Disable greeting
        set fish_greeting

        # Notify after commands longer than 10s
        set -g __done_min_cmd_duration 10000

        # Tide prompt colors derived from the active Stylix base16 scheme.
        # Uses semantic base16 slots so colors adapt automatically when the
        # scheme changes across machines.
        set -U tide_pwd_bg_color ${colors.base09}
        set -U tide_pwd_color_dirs ${colors.base01}
        set -U tide_pwd_color_anchors ${colors.base00}
        set -U tide_pwd_color_truncated_dirs ${colors.base02}
        set -U tide_git_bg_color ${colors.base0B}
        set -U tide_git_bg_color_unstable ${colors.base0A}
        set -U tide_git_bg_color_urgent ${colors.base08}
        set -U tide_git_color_branch ${colors.base00}
        set -U tide_git_color_conflicted ${colors.base00}
        set -U tide_git_color_dirty ${colors.base00}
        set -U tide_git_color_operation ${colors.base00}
        set -U tide_git_color_staged ${colors.base00}
        set -U tide_git_color_stash ${colors.base00}
        set -U tide_git_color_untracked ${colors.base00}
        set -U tide_git_color_upstream ${colors.base00}
        set -U tide_cmd_duration_bg_color ${colors.base0A}
        set -U tide_cmd_duration_color ${colors.base00}
        set -U tide_status_bg_color ${colors.base01}
        set -U tide_status_color ${colors.base0B}
        set -U tide_status_bg_color_failure ${colors.base08}
        set -U tide_status_color_failure ${colors.base07}
        set -U tide_jobs_bg_color ${colors.base02}
        set -U tide_jobs_color ${colors.base0B}
        set -U tide_context_bg_color ${colors.base02}
        set -U tide_context_color_default ${colors.base05}
        set -U tide_context_color_root ${colors.base0A}
        set -U tide_context_color_ssh ${colors.base09}
        set -U tide_character_color ${colors.base0B}
        set -U tide_character_color_failure ${colors.base08}
        set -U tide_time_bg_color ${colors.base04}
        set -U tide_time_color ${colors.base00}
        set -U tide_prompt_color_frame_and_connection ${colors.base03}
        set -U tide_prompt_color_separator_same_color ${colors.base04}
        set -U tide_os_bg_color ${colors.base08}
        set -U tide_os_color ${colors.base00}
        set -U tide_nix_shell_bg_color ${colors.base0D}
        set -U tide_nix_shell_color ${colors.base00}
        set -U tide_node_bg_color ${colors.base0B}
        set -U tide_node_color ${colors.base00}
        set -U tide_python_bg_color ${colors.base0A}
        set -U tide_python_color ${colors.base0D}
        set -U tide_go_bg_color ${colors.base0C}
        set -U tide_go_color ${colors.base00}
        set -U tide_rustc_bg_color ${colors.base09}
        set -U tide_rustc_color ${colors.base00}
        set -U tide_java_bg_color ${colors.base09}
        set -U tide_java_color ${colors.base00}
        set -U tide_docker_bg_color ${colors.base0D}
        set -U tide_docker_color ${colors.base00}
        set -U tide_kubectl_bg_color ${colors.base0D}
        set -U tide_kubectl_color ${colors.base00}
        set -U tide_terraform_bg_color ${colors.base0E}
        set -U tide_terraform_color ${colors.base00}
        set -U tide_aws_bg_color ${colors.base09}
        set -U tide_aws_color ${colors.base00}
        set -U tide_direnv_bg_color ${colors.base0A}
        set -U tide_direnv_bg_color_denied ${colors.base08}
        set -U tide_direnv_color ${colors.base00}
        set -U tide_direnv_color_denied ${colors.base00}
        set -U tide_private_mode_bg_color ${colors.base04}
        set -U tide_private_mode_color ${colors.base00}
        set -U tide_vi_mode_bg_color_default ${colors.base04}
        set -U tide_vi_mode_bg_color_insert ${colors.base0C}
        set -U tide_vi_mode_bg_color_replace ${colors.base0B}
        set -U tide_vi_mode_bg_color_visual ${colors.base09}
        set -U tide_vi_mode_color_default ${colors.base00}
        set -U tide_vi_mode_color_insert ${colors.base00}
        set -U tide_vi_mode_color_replace ${colors.base00}
        set -U tide_vi_mode_color_visual ${colors.base00}
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
        {
          name = "done";
          inherit (pkgs.fishPlugins.done) src;
        }
        {
          name = "bang-bang";
          inherit (pkgs.fishPlugins.bang-bang) src;
        }
      ];
    };
  };

  # Run tide's non-interactive configurator after home-manager writes files.
  # This sets the prompt layout (style, separators, icons, etc.); colors are
  # overridden separately via interactiveShellInit above.
  #
  # The --auto flags below must cover every choice in the tide version shipped
  # by nixpkgs (currently v6.2.0). Choices live under
  # functions/tide/configure/choices/{all,rainbow,powerline}/ in the tide repo.
  # If a nixpkgs bump adds or renames a choice, this activation will fail and
  # log a warning — check `tide configure --auto` output to diagnose.
  home = lib.mkIf homelabCfg.programs.fish.enable {
    activation = {
      configure-tide = lib.hm.dag.entryAfter ["writeBoundary"] ''
        ${pkgs.fish}/bin/fish -c "tide configure --auto \
          --style=Rainbow \
          --prompt_colors='True color' \
          --show_time='24-hour format' \
          --rainbow_prompt_separators=Angled \
          --powerline_prompt_heads=Sharp \
          --powerline_prompt_tails=Flat \
          --powerline_prompt_style='Two lines, character and frame' \
          --prompt_connection=Dotted \
          --prompt_connection_andor_frame_color=Dark \
          --powerline_right_prompt_frame=Yes \
          --prompt_spacing=Compact \
          --icons='Many icons' \
          --transient=Yes" > /dev/null 2>&1 || echo "WARNING: tide configure --auto failed — prompt layout may be missing"
      '';
    };
  };
}
