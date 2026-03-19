# Overlay — exposes all custom packages from nix/pkgs/ in the nixpkgs set.
final: prev: (import ../pkgs {
  pkgs = prev;

  inherit (prev) lib;
})
