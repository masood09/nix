{config, ...}: let
  homelabCfg = config.homelab;
in {
  local = {
    dock = {
      enable = true;
      username = homelabCfg.primaryUser.userName;
      entries = [
        {path = "/Applications/Zen.app";}
        {path = "/Applications/Google Chrome.app";}
        {path = "/Applications/Ghostty.app";}
        {path = "/opt/homebrew/Cellar/emacs-plus@30/30.2/Emacs.app";}
        {path = "/Applications/Slack.app";}
        {path = "/Applications/zoom.us.app";}
        {path = "/System/Applications/System Settings.app";}
      ];
    };
  };
}
