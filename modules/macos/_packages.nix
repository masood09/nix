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
      "d12frosted/homebrew-emacs-plus" = inputs.homebrew-emacs-plus;
      "jackielii/homebrew-tap" = inputs.homebrew-jackielii-tap;
      "FelixKratz/homebrew-formulae" = inputs.homebrew-sketchybar-tap;
      "homebrew/homebrew-bundle" = inputs.homebrew-bundle;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "koekeishiya/homebrew-formulae" = inputs.homebrew-koekeishiya-yabai;
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
      "d12frosted/emacs-plus/emacs-plus"
      "jackielii/tap/skhd-zig"
      "koekeishiya/formulae/yabai"
      "sketchybar"
    ];
    taps = builtins.attrNames config.nix-homebrew.taps;
    casks = [
      "anythingllm"
      "appcleaner"
      "balenaetcher"
      "discord"
      "docker-desktop"
      "ghostty"
      "lm-studio"
      "obsidian"
      "opencloud"
      "pgadmin4"
      "raycast"
      "spacelauncher"
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
