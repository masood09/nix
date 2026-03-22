# macOS Dock layout — personal apps (browser, editor, chat, media).
{config, ...}: let
  homelabCfg = config.homelab;
in {
  local = {
    dock = {
      enable = true;
      username = homelabCfg.primaryUser.userName;
      entries = [
        # Web browser (Zen - Firefox-based, installed via home-manager)
        {path = "/Users/${homelabCfg.primaryUser.userName}/Applications/Home Manager Apps/Zen Browser (Beta).app";}
        # Text editor and development environment
        {path = "/Applications/Emacs.app";}
        # Terminal emulator (kitty installed via home-manager, lives in user directory)
        {path = "/Users/${homelabCfg.primaryUser.userName}/Applications/Home Manager Apps/kitty.app";}
        # Communication apps
        {path = "/Applications/Element.app";}
        {path = "/Applications/Discord.app";}
        {path = "/System/Applications/Messages.app";}
        # Productivity apps
        {path = "/System/Applications/Reminders.app";}
        {path = "/System/Applications/Notes.app";}
        # Media player
        {path = "/Applications/Infuse.app";}
        # System utilities
        {path = "/System/Applications/System Settings.app";}
      ];
    };
  };
}
