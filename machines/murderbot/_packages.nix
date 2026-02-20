{lib, ...}: {
  homebrew = {
    casks = lib.mkAfter [
      "balenaetcher"
      "discord"
      "docker-desktop"
      "element"
      "karabiner-elements"
      "opencloud"
      "pgadmin4"
      "zoom"
    ];
    masApps = {
      "Bitwarden Desktop" = 1352778147;
      "Home Assistant" = 1099568401;
      "Infuse" = 1136220934;
      "Windows App" = 1295203466;
      "Xcode" = 497799835;
    };
  };
}
