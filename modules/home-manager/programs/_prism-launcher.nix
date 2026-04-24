# Prism Launcher — Minecraft launcher with bundled JDKs.
# JRE 17: required for 1.18–1.20.4 and Fabric/Forge modpacks that explicitly pin it (e.g. Homestead).
# JRE 21: required for 1.20.5+ stable releases.
# JRE 25: for current snapshots (sourced from nixpkgs-unstable; see TECH DEBT below).
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
            pkgs.temurin-jre-bin-17
          ];
        })
      ];
    };
  };
}
