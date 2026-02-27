{
  config,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  environment.systemPackages = with pkgs; [
    coreutils
    coreutils-prefixed
    fontconfig
  ];

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
      "emacs-plus-app"
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
