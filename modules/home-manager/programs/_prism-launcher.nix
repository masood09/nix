# Prism Launcher — Minecraft launcher with bundled JDKs.
# JRE 25 for current snapshots (25.x), JRE 21 for stable releases (1.17–1.20.x).
{
  homelabCfg,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.prism-launcher;
  # TECH DEBT: temurin-jre-bin-25 is pulled from nixpkgs-unstable because the
  # package has not landed in nixos-25.11. Drop the inputs.nixpkgs-unstable
  # reference once it arrives in the stable channel.
  pkgsUnstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        (pkgs.prismlauncher.override {
          jdks = [
            pkgsUnstable.temurin-jre-bin-25
            pkgs.temurin-jre-bin-21
          ];
        })
      ];
    };
  };
}
