# oh-pi-themes — color themes for the pi coding agent (@ifi/oh-pi-themes).
#
# Theme-only npm artifact: six JSON files, no runtime dependencies, so the
# registry tarball is fetched and unpacked rather than built with
# buildNpmPackage — nothing here needs Node at runtime, and the result is a
# plain read-only tree of theme files.
#
# Deliberately NOT installed through Pi's own package manager (`pi install
# npm:@ifi/oh-pi-themes`): that runs npm at startup, records the declaration in
# the user-owned ~/.pi/agent/settings.json, and re-downloads the package
# outside Nix. Pi reads the same theme files from ~/.pi/agent/themes, which
# modules/home-manager/programs/_pi.nix fills with symlinks into this package.
#
# Upstream publishes very frequently (25 releases in seven months); Renovate
# bumps the pin below, and the fetchzip hash is the unpacked tree — a theme
# rename or a changed file shows up as an eval-time hash mismatch, not a
# silent config drift.
{
  lib,
  fetchzip,
  ...
}: let
  # renovate: datasource=npm depName=@ifi/oh-pi-themes
  version = "0.5.1";
in
  fetchzip {
    name = "oh-pi-themes-${version}";
    url = "https://registry.npmjs.org/@ifi/oh-pi-themes/-/oh-pi-themes-${version}.tgz";
    hash = "sha256-seqN+pAc0s+houIeJhfdo6temfvp26ovjFtM3yU9LCU=";
    stripRoot = true;

    meta = {
      description = "Color themes for the pi coding agent (gruvbox, nord, catppuccin, tokyo-night, cyberpunk)";
      homepage = "https://github.com/ifiokjr/oh-pi/tree/main/packages/themes";
      license = lib.licenses.mit;
    };
  }
