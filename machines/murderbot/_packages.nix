# Machine-specific Homebrew casks and Mac App Store apps (personal).
{lib, ...}: {
  homebrew = {
    casks = lib.mkAfter [
      "balenaetcher"
      "discord"
      "docker-desktop"
      # TECH DEBT: Element on Homebrew because nixpkgs `element-desktop` fails
      # to build on Darwin — `electron-builder@26.x` eagerly calls bare `actool`
      # (no absolute path) from `app-builder-lib/.../macosIconComposer.ts` at
      # module-load time, and the Nix builder's scrubbed PATH can't reach
      # /usr/bin/actool even with `sandbox = false`. The HM
      # `programs.element-desktop` module is intentionally not enabled on this
      # host (see ./default.nix); drop this cask and re-enable the HM module
      # once nixpkgs picks up an upstream electron-builder fix or patches the
      # bare actool call to use an absolute path.
      "element"
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
