# macOS Dock layout — work apps (browser, editor, Slack, Zoom).
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
        {path = "/Applications/Google Chrome.app";}
        {path = "/Applications/Emacs.app";}
        {path = "/Applications/Slack.app";}
        {path = "/Applications/zoom.us.app";}
        {path = "/System/Applications/System Settings.app";}
      ];
    };
  };
}
