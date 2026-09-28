# Nixpkgs configuration and documentation settings.
#
# nixpkgs.config uses a merge function (see nixos/modules/misc/nixpkgs.nix)
# that only special-cases list-concatenation for allowUnfreePackages,
# packageOverrides, and perlPackageOverrides — permittedInsecurePackages is
# plain recursiveUpdate, so if two modules each set
# nixpkgs.config.permittedInsecurePackages directly, the last one evaluated
# silently clobbers the other instead of merging. homelab.insecurePackages
# is a normal listOf-str option (concatenates across modules as expected),
# collected here into the one nixpkgs.config definition for this key.
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      insecurePackages = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Insecure package names to permit (nixpkgs.config.permittedInsecurePackages). Add to this instead of setting nixpkgs.config.permittedInsecurePackages directly, since that option does not merge across modules.";
      };
    };
  };

  config = {
    nixpkgs = {
      config = {
        allowUnfree = true;
        dontPatchELF = true;
        permittedInsecurePackages = config.homelab.insecurePackages;

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
  };
}
