# NixOS service module for Nightscout — Node.js CGM dashboard with
# MongoDB backend, configurable display units, and environment file secrets.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.services.nightscout;
  runtimeNode = cfg.package.passthru.nodejs or pkgs.nodejs;
in {
  options = {
    services = {
      nightscout = {
        enable = lib.mkEnableOption "Enable Nightscout";

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.cgm-remote-monitor;
          description = "Nightscout package to run.";
        };

        port = lib.mkOption {
          default = 1337;
          type = lib.types.port;
        };

        displayUnits = lib.mkOption {
          type = lib.types.enum [
            "mg/dl"
            "mmol/L"
            "mmol"
          ];
          default = "mg/dl";
          description = ''
            DISPLAY_UNITS for Nightscout.

            Valid values:
              - "mg/dl"   (default)
              - "mmol/L"
              - "mmol"

            Setting to "mmol/L" or "mmol" puts the entire server
            into mmol mode by default. No additional configuration
            is required.
          '';
        };

        environmentFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          example = "/run/secrets/nightscout.env";
          description = ''
            File containing environment variables (KEY=VALUE per line)
            loaded by systemd before starting Nightscout.

            Use this file to store any credentials that have to be declared,
            instead of declaring under settings.
          '';
        };

        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = {};
          description = "Extra environment variables for Nightscout (KEY = VALUE).";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users = {
        nightscout = {
          isSystemUser = true;
          group = "nightscout";
        };
      };

      groups = {
        nightscout = {};
      };
    };

    systemd = {
      services = {
        nightscout = {
          description = "Nightscout";
          wantedBy = ["multi-user.target"];
          after = ["network.target"];

          serviceConfig =
            {
              User = "nightscout";
              Group = "nightscout";
              WorkingDirectory = "${cfg.package}/lib/node_modules/nightscout";

              ExecStart = "${runtimeNode}/bin/node ${cfg.package}/lib/node_modules/nightscout/lib/server/server.js";

              Restart = "always";
              RestartSec = 5;

              Environment = lib.mapAttrsToList (k: v: "${k}=${lib.escapeShellArg v}") ({
                  MONGODB_COLLECTION = "entries";
                  PORT = toString cfg.port;
                  DISPLAY_UNITS = cfg.displayUnits;
                  INSECURE_USE_HTTP = "true";
                }
                // cfg.environment);
            }
            // lib.optionalAttrs (cfg.environmentFile != null) {
              EnvironmentFile = cfg.environmentFile;
            };
        };
      };
    };
  };
}
