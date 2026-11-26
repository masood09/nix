# Options — console-mode: gaming vs inference on a shared GPU, following a
# Home Assistant binary_sensor.
{
  config,
  lib,
  ...
}: {
  options = {
    homelab = {
      services = {
        console-mode = {
          enable = lib.mkEnableOption ''
            switching the host between gaming mode (the Steam session runs,
            Strata is stopped and held) and inference mode (the Steam session
            is stopped, Strata runs), following a Home Assistant
            binary_sensor'';

          homeAssistant = {
            url = lib.mkOption {
              type = lib.types.str;
              default = "https://home.${config.networking.domain}";
              defaultText = lib.literalExpression ''"https://home.''${config.networking.domain}"'';
              description = "Base URL of Home Assistant; the REST API is under /api.";
            };

            entity = lib.mkOption {
              type = lib.types.strMatching "binary_sensor\\.[a-z0-9_]+";
              default = "binary_sensor.${config.networking.hostName}_gaming";
              defaultText = lib.literalExpression ''"binary_sensor.''${config.networking.hostName}_gaming"'';
              description = ''
                Entity whose state decides the mode: "on" is gaming, "off" is
                inference. Any other state (unavailable, unknown), and any
                failure to read it, leaves the mode as it is.
              '';
            };

            headerFile = lib.mkOption {
              type = lib.types.str;
              example = lib.literalExpression ''config.sops.templates."console-mode-ha.header".path'';
              description = ''
                File holding the whole header line
                `Authorization: Bearer <long-lived token>`, readable by the
                console-mode user. curl reads it with `-H @file`, so the token
                never appears in argv or the environment. A file holding only
                the bare token would send an invalid header.
              '';
            };
          };

          interval = lib.mkOption {
            type = lib.types.ints.between 1 300;
            default = 5;
            description = "Seconds between Home Assistant polls.";
          };

          inferenceDelay = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 120;
            description = ''
              Seconds the entity must stay off before inference mode is
              applied; the delay keeps quick input flips from costing a model
              load each.
            '';
          };

          gamingDelay = lib.mkOption {
            type = lib.types.ints.unsigned;
            default = 10;
            description = ''
              Seconds the entity must stay on before gaming mode is applied.
              A brief "on" (the sync box jumping to ixian's input while ixian
              wakes, until Home Assistant puts it back) would otherwise stop
              Strata mid-request. Polls are `interval` apart, so the real wait
              is up to one interval longer. 0 applies gaming mode at once.
            '';
          };

          userId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3021;
            description = "UID of the console-mode service user (see docs/service-registry.org).";
          };

          groupId = lib.mkOption {
            type = lib.types.ints.u16;
            default = 3021;
            description = "GID of the console-mode service group.";
          };
        };
      };
    };
  };
}
