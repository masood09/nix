# Controller wake — starts Gaming Mode from a controller gesture.
#
# Switch an 8BitDo Ultimate 2 on, then press Start and Home. A small
# listener (_controller-wake.py, whose header has the measurements behind
# the gesture) watches both controllers' gamepad devices and POSTs to a
# Home Assistant webhook. HA turns the TV on if needed (through the Shield
# over HDMI-CEC) and switches the sync box to HDMI 3, which makes
# binary_sensor.ixian_gaming on, so console-mode starts the Steam session.
#
# A gesture instead of "the controller connected": a reconnect after a
# signal drop, ixian booting with a controller on, or someone waking an
# idle controller with a stray press would otherwise all switch the TV.
#
# The webhook URL is a sops secret because HA webhook IDs act as passwords.
# HA sees the request from ixian's tailnet address, which it does not count
# as local, so the HA automation sets local_only: false.
{
  config,
  pkgs,
  ...
}: let
  urlSecret = config.sops.secrets."controller-wake/webhook-url".path;

  controllerWake =
    pkgs.writers.writePython3 "controller-wake" {
      flakeIgnore = ["E501"];
    }
    (builtins.readFile ./_controller-wake.py);
in {
  config = {
    systemd = {
      services = {
        controller-wake = {
          description = "Start Gaming Mode on a controller gesture (connect, Start, Home)";
          wantedBy = ["multi-user.target"];
          after = ["network-online.target"];
          wants = ["network-online.target"];

          serviceConfig = {
            ExecStart = controllerWake;
            Restart = "always";
            RestartSec = 5;

            DynamicUser = true;
            # /dev/input/event* nodes are root:input 0660.
            SupplementaryGroups = ["input"];
            LoadCredential = ["webhook-url:${urlSecret}"];

            DevicePolicy = "closed";
            DeviceAllow = ["char-input r"];
            ProtectHome = true;
            ProtectSystem = "strict";
            NoNewPrivileges = true;
            # AF_UNIX for name lookups through nscd.
            RestrictAddressFamilies = ["AF_UNIX" "AF_INET" "AF_INET6"];
          };
        };
      };
    };
  };
}
