# Kitty — GPU-accelerated terminal emulator themed by Stylix.
{
  homelabCfg,
  lib,
  ...
}: {
  programs = {
    kitty = {
      inherit (homelabCfg.programs.kitty) enable;

      settings = {
        # Font configuration
        font_size = lib.mkDefault 12;

        # Cursor
        cursor_shape = "block";
        cursor_blink_interval = 0;

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

        # Tab bar
        tab_bar_edge = "top";
        tab_bar_style = "powerline";
        tab_powerline_style = "slanted";

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
