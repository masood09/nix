# Machine-specific packages — work tools (k8s, GPG/YubiKey, work casks).
{
  lib,
  pkgs,
  ...
}: {
  environment = {
    systemPackages = with pkgs; [
      kubectx
      k9s
      shellcheck
    ];
  };

  homebrew = {
    onActivation = {
      cleanup = lib.mkForce "none";
    };

    brews = lib.mkAfter [
      "hopenpgp-tools" # Key validity checker and linter
      "pinentry-mac"
      "ykman" # Command line Yubikey configuration utility
      "hashicorp/tap/vault"
      "docker"
      "podman"
      "krunkit"
      "colima"
    ];

    taps = lib.mkAfter [
      "hashicorp/tap"
      "joemiller/taps"
      "slp/krunkit"
    ];

    casks = lib.mkAfter [
      "gcloud-cli"
      "podman-desktop"
    ];
  };
}
