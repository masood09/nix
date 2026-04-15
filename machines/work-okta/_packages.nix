# Machine-specific Homebrew overrides for work-okta.
# Corporate Artifactory proxy blocks all third-party taps, so shared
# taps/brews/casks from modules/macos/_packages.nix are force-cleared
# and only standard Homebrew packages are kept.
{lib, ...}: {
  homebrew = {
    onActivation = {
      # Disable zap on work machines — IT-managed apps and profiles
      # outside Nix's control would be removed by the default "zap" policy.
      cleanup = lib.mkForce "none";
    };

    # Blocked by Artifactory: d12frosted/emacs-plus, FelixKratz/formulae, nikitabobko/tap
    taps = lib.mkForce [];

    # Blocked (from third-party taps): borders, sketchybar, kanata
    brews = lib.mkForce [];

    # Blocked (from third-party taps): aerospace, emacs-plus-app
    casks = lib.mkForce [
      "alfred"
      "appcleaner"
      "emacs" # GUI Emacs from default registry (emacs-plus cask blocked by Artifactory)
      "shortcat"
    ];

    masApps = lib.mkForce {};
  };
}
