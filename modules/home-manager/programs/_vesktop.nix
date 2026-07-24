# Vesktop — a Vencord-based Discord client with proper Wayland support and
# working screenshare (unlike the official Electron client). Serves as the read
# side for Grafana alert notifications, delivered to a Discord channel via webhook.
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.vesktop;
in {
  config = lib.mkIf cfg.enable {
    home = {
      packages = [pkgs.vesktop];
    };
  };
}
