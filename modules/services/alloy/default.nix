# Alloy — Grafana's telemetry agent. Ships logs to Loki and metrics to Prometheus.
# Runs with hostname-aware env var for instance labelling.
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

        environmentFile = config.sops.secrets."alloy/.env".path;

        extraFlags = [
          "--disable-reporting"
        ];
      };
    };

    systemd = {
      services = {
        alloy = {
          environment = {
            ALLOY_HOSTNAME = config.homelab.networking.hostName;
          };

          # The upstream module sets DynamicUser = true, which would allocate
          # a transient UID at runtime.  We need a stable UID/GID (3000) that
          # is consistent across reboots and matches the service registry, so
          # override it in favour of the static user defined below.
          serviceConfig = {
            DynamicUser = lib.mkForce false;
            User = "alloy";
            Group = "alloy";
          };
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

    environment = {
      etc = {
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
  };
}
