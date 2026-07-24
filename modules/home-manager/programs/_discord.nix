# Discord — voice/text chat desktop client. Serves as the read side for Grafana
# alert notifications (delivered to a Discord channel via webhook).
{
  homelabCfg,
  lib,
  pkgs,
  ...
}: let
  cfg = homelabCfg.programs.discord;
in {
  config = lib.mkIf cfg.enable {
    home = {
      packages = [pkgs.discord];
    };
  };
}
