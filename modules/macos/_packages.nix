{
  config,
  inputs,
  vars,
  ...
}: {
  nix-homebrew = {
    enable = true;
    user = vars.userName;
    mutableTaps = false;
    taps = {
      "acsandmann/homebrew-tap" = inputs.homebrew-acsandmann;
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
      "acsandmann/tap/rift"
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "anythingllm"
      "appcleaner"
      "balenaetcher"
      "discord"
      "docker-desktop"
      "emacs-app"
      "ghostty"
      "hyperkey"
      "lm-studio"
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
