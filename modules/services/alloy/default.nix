{
  config,
  lib,
  ...
}: let
  alloyCfg = config.homelab.services.alloy;
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
  };

  config = lib.mkIf alloyCfg.enable {
    services = {
      alloy = {
        inherit (alloyCfg) enable;

        environmentFile = config.sops.secrets."alloy.env".path;

        extraFlags = [
          "--disable-reporting"
        ];
      };
    };

    systemd.services = {
      alloy = {
        environment = {
          ALLOY_HOSTNAME = config.homelab.networking.hostName;
        };
      };
    };

    users = {
      users = {
        alloy = {
          isSystemUser = true;
          group = "alloy";
          uid = alloyCfg.userId;
        };
      };

      groups = {
        alloy = {
          gid = alloyCfg.groupId;
        };
      };
    };

    environment.etc = {
      "alloy/config.alloy" = {
        source = ./config.alloy;
      };
      "alloy/loki.alloy" = {
        source = ./loki.alloy;
      };
      "alloy/prometheus.alloy" = {
        source = ./prometheus.alloy;
      };
    };
  };
}
