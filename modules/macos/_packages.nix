{
  config,
  inputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  nix-homebrew = {
    enable = true;
    user = homelabCfg.primaryUser.userName;
    mutableTaps = false;
    taps = {
      "d12frosted/homebrew-emacs-plus" = inputs.homebrew-emacs-plus;
      "FelixKratz/homebrew-formulae" = inputs.homebrew-sketchybar-tap;
      "nikitabobko/homebrew-tap" = inputs.homebrew-nikitabobko-tap;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-core" = inputs.homebrew-core;
    };
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
      "d12frosted/emacs-plus/emacs-plus"
      "sketchybar"
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "nikitabobko/tap/aerospace"
      "appcleaner"
      "balenaetcher"
      "discord"
      "docker-desktop"
      "element"
      "ghostty"
      "karabiner-elements"
      "obsidian"
      "opencloud"
      "pgadmin4"
      "raycast"
      "tailscale-app"
      "zoom"
      "zen"
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Bitwarden Desktop" = 1352778147;
      "Home Assistant" = 1099568401;
      "Infuse" = 1136220934;
      "Unarchiver" = 425424353;
      "Windows App" = 1295203466;
      "Xcode" = 497799835;
    };
  };
}
