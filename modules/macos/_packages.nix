# macOS packages — Homebrew casks for GUI apps and taps for formulae
# not available in nixpkgs (Aerospace, SketchyBar, Kanata, etc.).
# `cleanup = "zap"` removes apps not listed here on activation.
{
  config,
  pkgs,
  inputs,
  ...
}: let
  homelabCfg = config.homelab;
in {
  environment = {
    systemPackages = with pkgs; [
      # Zen browser now managed via home-manager module
    ];
  };

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
      "kanata"
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
      "karabiner-elements"
      "shortcat"
      "tailscale-app"
      # Zen browser now installed via Nix (see systemPackages above)
    ];
    masApps = {
      "Amphetamine" = 937984704;
      "Unarchiver" = 425424353;
    };
  };
}
