{lib, ...}: {
  homebrew = {
    brews = lib.mkAfter [
      "hopenpgp-tools" # Key validity checker and linter
      "pinentry-mac"
      "ykman" # Command line Yubikey configuration utility
    ];
  };
}
