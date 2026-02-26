{
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    kubectx
    k9s
  ];

  homebrew = {
    onActivation = {
      cleanup = lib.mkForce "none";
    };

    brews = lib.mkAfter [
      "hopenpgp-tools" # Key validity checker and linter
      "pinentry-mac"
      "ykman" # Command line Yubikey configuration utility
      "hashicorp/tap/vault"
    ];

    taps = lib.mkAfter [
      "hashicorp/tap"
      "joemiller/taps"
    ];

    casks = lib.mkAfter [
      "gcloud-cli"
    ];
  };
}
