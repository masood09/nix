{lib, ...}: {
  homebrew = {
    brews = lib.mkAfter [
      "hopenpgp-tools" # Key validity checker and linter
      "pinentry-mac"
      "ykman" # Command line Yubikey configuration utility
      "hashicorp/tap/vault"
    ];

    casks = lib.mkAfter [
      "gcloud-cli"
    ];
  };
}
