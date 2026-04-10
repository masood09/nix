# Kitty — GPU-accelerated terminal emulator themed by Stylix.
#
# Settings are mostly platform-agnostic; the one split lives on `font_size`,
# where Linux and Darwin use different defaults (see the comment at the
# `font_size` line for the rationale and history).
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  fishEnabled = homelabCfg.programs.fish.enable or false;
in {
  programs = {
    kitty = {
      inherit (homelabCfg.programs.kitty) enable;

      settings = {
        # Launch fish as the interactive shell without changing the login shell,
        # avoiding home-manager activation issues with non-POSIX shells.
        shell = lib.mkIf fishEnabled "${pkgs.fish}/bin/fish";

        # Font configuration.
        #
        # Linux baseline is 12. That value has been in place since the module
        # was first written and happens to match Doom Emacs at `:size 16`
        # visually on the current NixOS desktops (gruvbox/JetBrainsMono).
        #
        # Darwin defaults to 16 as a user comfort preference, not a measured
        # Emacs-equivalence — 12 rendered too small on Retina, and although
        # 14 was the closest visual match to Doom's `:size 16`, the user
        # preferred the slightly-larger 16 for day-to-day reading. If you're
        # tempted to "fix" this to 14 to match Emacs, don't: it's intentional.
        #
        # Kept as `mkDefault` so any machine can still override locally via
        # `programs.kitty.settings.font_size` without touching this module.
        font_size = lib.mkDefault (
          if pkgs.stdenv.isDarwin
          then 16
          else 12
        );

        # Cursor
        cursor_shape = "underline";
        cursor_blink_interval = 0;
        cursor_underline_thickness = "0.15";

        # Scrollback
        scrollback_lines = 10000;

        # Window
        window_padding_width = 8;
        confirm_os_window_close = 0;

        # Performance
        repaint_delay = 10;
        input_delay = 3;
        sync_to_monitor = "yes";

        # Shell integration
        shell_integration = "enabled";

        # Disable tab bar (tiling WM handles window management)
        tab_bar_min_tabs = 2;

        # Mouse
        copy_on_select = "yes";
        strip_trailing_spaces = "smart";
      };

      # Keyboard shortcuts
      keybindings = {
        # Tab management
        "ctrl+shift+t" = "new_tab";
        "ctrl+shift+w" = "close_tab";
        "ctrl+shift+right" = "next_tab";
        "ctrl+shift+left" = "previous_tab";

        # Window management
        "ctrl+shift+enter" = "new_window";
        "ctrl+shift+]" = "next_window";
        "ctrl+shift+[" = "previous_window";

        # Font size
        "ctrl+shift+equal" = "increase_font_size";
        "ctrl+shift+minus" = "decrease_font_size";
        "ctrl+shift+0" = "restore_font_size";
      };
    };
  };
}
