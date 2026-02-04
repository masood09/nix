{lib, ...}: let
  dropRuleType = lib.types.submodule (_: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Human-friendly name for the rule (comment only).";
        example = "authentik: drop metrics 200";
      };

      unit = lib.mkOption {
        type = lib.types.str;
        description = "Systemd unit label to match (e.g. podman-ittools.service).";
        example = "podman-ittools.service";
      };

      expression = lib.mkOption {
        type = lib.types.str;
        description = "RE2 regex to match against the raw log line (MESSAGE).";
        example = ".*\"GET / HTTP/[^\"]+\" 200 .*\"Uptime-Kuma/.*";
      };
    };
  });
in {
  options.homelab.services.alloy = {
    enable = lib.mkOption {
      default = true;
      type = lib.types.bool;
      description = ''
        Whether to enable Grafana Alloy.
      '';
    };

    userId = lib.mkOption {
      default = 3000;
      type = lib.types.ints.u16;
      description = "User ID of Alloy user";
    };

    groupId = lib.mkOption {
      default = 3000;
      type = lib.types.ints.u16;
      description = "Group ID of Alloy group";
    };

    loki = {
      systemd = {
        dropEnable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable the systemd_drop Loki pipeline (noise filtering).";
        };

        dropRules = lib.mkOption {
          type = lib.types.listOf dropRuleType;
          default = [];
          description = ''
            List of log drop rules rendered into a `loki.process "systemd_drop"` pipeline.

            Each rule becomes: stage.match { selector = "..."; stage.drop { expression = "..." } }
          '';
        };
      };
    };
  };
}
