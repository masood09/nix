# Nixpkgs configuration and documentation settings.
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      dontPatchELF = true;

      # TECH DEBT: stremio depends on Qt5 WebEngine (qtwebengine-5.15.19),
      # which is unmaintained upstream and based on an obsolete Chromium fork.
      # Accept the risk for this media-only app on home desktops. Re-evaluate
      # when stremio migrates to Qt6 or an alternative packaging appears.
      permittedInsecurePackages = [
        "qtwebengine-5.15.19"
      ];

      packageOverrides = pkgs: {
        inherit (pkgs) stdenv;
      };
    };
  };

  # Disable man and info pages to reduce closure size.
  documentation = {
    man = {
      enable = false;
    };
    info = {
      enable = false;
    };
  };
}
