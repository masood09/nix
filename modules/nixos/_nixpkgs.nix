# Nixpkgs configuration and documentation settings.
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      dontPatchELF = true;

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
