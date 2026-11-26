# Game state — tells Home Assistant whether a game is being played, for
# automations such as dimming the TV room's lights.
#
# A small poller (_game-state.py, whose header has the measurements) reports
# none / playing / paused to a Home Assistant webhook whenever it changes:
# a game is running when Steam's launch process for it exists, and it is
# "paused" while the Steam menu is in front of it (gamescope's focused app).
# HA keeps it as sensor.ixian_game, a trigger-based template sensor with the
# game's AppID and name as attributes.
#
# It runs as the console user, which owns Steam's processes and files and
# reaches gamescope's X display without an Xauthority. The webhook URL is a
# sops secret because HA webhook IDs act as passwords.
{
  config,
  lib,
  pkgs,
  ...
}: let
  gamingUser = config.homelab.desktop.gaming.user;
  gameState =
    pkgs.writers.writePython3 "game-state" {
      libraries = [pkgs.python3Packages.vdf];
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./_game-state.py);
in {
  config = {
    systemd = {
      services = {
        game-state = {
          description = "Report the game being played (none, playing, paused) to Home Assistant";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];
          serviceConfig = {
            ExecStart = "${gameState} ${lib.getExe pkgs.xprop}";
            User = gamingUser;
            Restart = "always";
            RestartSec = 5;
            LoadCredential = ["webhook-url:${config.sops.secrets."game-state/webhook-url".path}"];
            ProtectSystem = "strict";
            ProtectHome = "read-only";
            PrivateTmp = false; # gamescope's X socket is in /tmp/.X11-unix
            NoNewPrivileges = true;
            RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
          };
        };
      };
    };
  };
}
