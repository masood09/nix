{
  config,
  lib,
  ...
}: let
  alloyCfg = config.homelab.services.alloy;
in {
  imports = [
    ./loki-systemd-drop.nix
    ./options.nix
  ];

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
      "alloy/loki-systemd.alloy" = {
        source = ./loki-systemd.alloy;
      };
      "alloy/prometheus-node-exporter.alloy" = {
        source = ./prometheus-node-exporter.alloy;
      };
    };
  };
}
