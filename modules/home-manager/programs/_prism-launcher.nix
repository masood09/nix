# Prism Launcher — Minecraft launcher with bundled JDKs.
# JRE 17: required for 1.18–1.20.4 and Fabric/Forge modpacks that explicitly pin it (e.g. Homestead).
# JRE 21: required for 1.20.5+ stable releases.
# JRE 25: for current snapshots.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.prism-launcher;
in {
  config = lib.mkIf cfg.enable {
    home = {
      packages = [
        (pkgs.prismlauncher.override {
          jdks = [
            pkgs.temurin-jre-bin-25
            pkgs.temurin-jre-bin-21
            pkgs.temurin-jre-bin-17
          ];
        })
      ];
    };
  };
}
