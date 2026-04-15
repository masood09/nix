# macOS Dock layout for work-okta — browser, editor, comms, settings.
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
        # Emacs installed manually (emacs-plus cask blocked by Artifactory)
        {path = "/Applications/Emacs.app";}
        {path = "/Users/${homelabCfg.primaryUser.userName}/Applications/Home Manager Apps/kitty.app";}
        {path = "/Applications/Slack.app";}
        {path = "/Applications/zoom.us.app";}
        {path = "/System/Applications/System Settings.app";}
      ];
    };
  };
}
