# OpenCloud Desktop — file sync client for OpenCloud.
# Installs the package on Linux desktops; auto-start is handled by the Niri
# spawn-at-startup list in niri/default.nix.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (homelabCfg.programs.opencloud-desktop.enable or false) {
    home = {
      packages = lib.mkIf pkgs.stdenv.isLinux [
        pkgs.opencloud-desktop
      ];
    };
  };
}
