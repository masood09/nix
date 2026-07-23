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
    # -------------------------
    # Loki drop rules (fleet-wide journal noise)
    # -------------------------
    #
    # dbus logs "Ignoring duplicate name ... in service file ..." at priority
    # err, so the journald priority mapping labels it level="error" and it
    # lands in the same stream as real failures. It is benign: NixOS puts the
    # system path on the session bus search path explicitly *and* via
    # standard_session_servicedirs, so dbus scans the same directory twice and
    # reports the second copy of each systemd unit file it finds. Nothing is
    # broken and nothing is lost — dbus keeps the first definition.
    #
    # Emitted once per bus startup, i.e. on every login/SSH session, on every
    # host in the fleet.
    homelab = {
      services = {
        alloy = {
          loki = {
            systemd = {
              dropRules = lib.mkBefore (
                map (unit: {
                  name = "dbus: drop duplicate service-file names (${unit})";
                  inherit unit;
                  expression = "^Ignoring duplicate name '[^']*' in service file .*";
                }) [
                  "user@${toString config.homelab.primaryUser.userId}.service"
                  # Desktops run dbus-broker rather than dbus-daemon; the unit
                  # does not exist on servers, where the rule is simply inert.
                  "dbus-broker.service"
                ]
              );
            };
          };
        };
      };
    };

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
      # Textfile collector drop-box. Batch jobs write *.prom files here and the
      # unix exporter picks them up on its next scrape. Root-owned and
      # world-readable: writers are root-run oneshots, alloy only reads.
      tmpfiles = {
        rules = [
          "d ${toString alloyCfg.textfileDir} 0755 root root -"
        ];
      };

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
        "alloy/alloy-self.alloy" = {
          source = ./alloy-self.alloy;
        };
      };
    };
  };
}
