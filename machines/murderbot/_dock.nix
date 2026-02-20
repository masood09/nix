{config, ...}: let
  homelabCfg = config.homelab;
in {
  local = {
    dock = {
      enable = true;
      username = homelabCfg.primaryUser.userName;
      entries = [
        {path = "/Applications/Zen.app";}
        {path = "/Applications/Ghostty.app";}
        {path = "/opt/homebrew/Cellar/emacs-plus@30/30.2/Emacs.app";}
        {path = "/Applications/Element.app";}
        {path = "/Applications/Discord.app";}
        {path = "/System/Applications/Messages.app";}
        {path = "/System/Applications/Reminders.app";}
        {path = "/System/Applications/Notes.app";}
        {path = "/Applications/Infuse.app";}
        {path = "/System/Applications/System Settings.app";}
      ];
    };
  };
}
