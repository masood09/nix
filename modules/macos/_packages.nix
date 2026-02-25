{config, ...}: let
  homelabCfg = config.homelab;
in {
  nix-homebrew = {
    enable = true;
    user = homelabCfg.primaryUser.userName;
    mutableTaps = true;
  };

  homebrew = {
    enable = true;
    global = {
      autoUpdate = true;
    };
    onActivation = {
      autoUpdate = false;
      upgrade = false;
      cleanup = "zap";
    };
    brews = [
      "borders"
      "d12frosted/emacs-plus/emacs-plus"
      "sketchybar"
    ];
    taps = [
      "d12frosted/emacs-plus"
      "FelixKratz/formulae"
      "nikitabobko/tap"
    ];
    casks = [
      "nikitabobko/tap/aerospace"
      "alfred"
      "appcleaner"
      "ghostty"
      "karabiner-elements"
      "shortcat"
      "tailscale-app"
      "zen"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Unarchiver" = 425424353;
    };
  };
}
