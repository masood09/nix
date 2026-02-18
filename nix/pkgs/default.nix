{
  pkgs,
  lib,
}: let
  entries = builtins.readDir ./.;

  # candidate package directories
  dirEntries = lib.filterAttrs (_: t: t == "directory") entries;

  # only keep dirs that actually have a default.nix
  isPkgDir = name:
    builtins.pathExists (./. + "/${name}/default.nix");

  pkgDirs = lib.filterAttrs (name: _: isPkgDir name) dirEntries;
in
  lib.mapAttrs (
    name: _:
      pkgs.callPackage (./. + "/${name}") {}
  )
  pkgDirs
