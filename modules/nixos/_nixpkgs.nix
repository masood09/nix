# Nixpkgs configuration — allow unfree packages and disable docs on servers.
{
  nixpkgs = {
    config = {
      allowUnfree = true;
      dontPatchELF = true;

      packageOverrides = pkgs: {
        inherit (pkgs) stdenv;
      };

      # Servers don't need man pages or documentation
      documentation = {
        enable = false;
      };

      man = {
        enable = false;
      };

      info = {
        enable = false;
      };
    };
  };
}
