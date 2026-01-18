{
  nixpkgs.config = {
    allowUnfree = true;
    dontPatchELF = true;

    packageOverrides = pkgs: {
      inherit (pkgs) stdenv;
    };

    documentation.enable = false;
    man.enable = false;
    info.enable = false;
  };
}
