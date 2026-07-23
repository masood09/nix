# MongoDB — document database used by Nightscout. Auth enabled with
# root password from sops. ZFS-backed data directory.
# TLS is intentionally omitted: only Nightscout connects, and it does so
# over localhost (Unix socket / 127.0.0.1). No network exposure.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.mongodb;
  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "mongodb";
    inherit (cfg) dataDir;
    user = "mongodb";
    group = "mongodb";
    mainServices = ["mongodb"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-mongodb";
    };
  };

  alloyEnabled = homelabCfg.services.alloy.enable;

  # Exporter launcher that keeps the mongo credential out of the Nix store and
  # process arguments: read the root password at runtime and pass the connection
  # string via MONGODB_URI (which percona mongodb_exporter reads), rather than the
  # upstream module's hardcoded --mongodb.uri command-line flag. The password is
  # percent-encoded so URI-reserved characters can't corrupt the connection URI.
  mongodbExporterStart = pkgs.writeShellScript "mongodb-exporter-start" ''
    set -euo pipefail
    raw="$(<${config.sops.secrets."mongodb/root-password".path})"
    password="$(printf '%s' "$raw" | ${lib.getExe pkgs.jq} -sRr @uri)"
    export MONGODB_URI="mongodb://root:$password@127.0.0.1:27017/?authSource=admin"
    exec ${lib.getExe pkgs.prometheus-mongodb-exporter} \
      --web.listen-address="127.0.0.1:${toString config.services.prometheus.exporters.mongodb.port}" \
      --collect-all
  '';
in {
  imports = [
    ./alloy.nix
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    # ZFS dataset for dataDir
    homelab = {
      zfs = {
        datasets = {
          mongodb = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;
            requiredBy = ["mongodb.service"];

            restic = {
              enable = true;
            };
          };
        };
      };
    };

    services = {
      mongodb = {
        inherit (cfg) enable;

        dbpath = cfg.dataDir;
        enableAuth = true;
        initialRootPasswordFile = config.sops.secrets."mongodb/root-password".path;
        pidFile = "/run/mongodb/mongodb.pid";
      };

      # Metrics exporter. Enabled only when Alloy is present to scrape it. The
      # connection/credentials are handled by the ExecStart override below, so
      # the upstream `uri` option (which would land in the store) is left unused.
      prometheus = {
        exporters = {
          mongodb = lib.mkIf alloyEnabled {
            enable = true;
            listenAddress = "127.0.0.1";
          };
        };
      };
    };

    # Upstream NixOS mongodb module has no systemd hardening
    systemd = lib.mkMerge [
      permSvc.systemd

      {
        services = {
          mongodb = {
            serviceConfig = {
              NoNewPrivileges = true;
              PrivateDevices = true;
              PrivateTmp = true;
              ProtectHome = true;
              ProtectSystem = "strict";
              RuntimeDirectory = "mongodb";
              ReadWritePaths = [cfg.dataDir];
            };
          };
        };
      }

      (lib.mkIf alloyEnabled {
        services = {
          # Run the exporter as the mongodb user (so it can read the root-password
          # secret, owner mongodb) and via the credential-safe launcher. Ordered
          # after the role grant so serverStatus/getDiagnosticData are authorized.
          prometheus-mongodb-exporter = {
            after = ["mongodb.service" "mongodb-exporter-grant.service"];
            requires = ["mongodb.service"];
            wants = ["mongodb-exporter-grant.service"];

            serviceConfig = {
              User = lib.mkForce "mongodb";
              Group = lib.mkForce "mongodb";
              ExecStart = lib.mkForce (toString mongodbExporterStart);
            };
          };

          # Grant clusterMonitor to the existing root user so the exporter's
          # monitoring commands are authorized (the module-created root user has
          # userAdmin/dbAdmin/readWrite AnyDatabase but not clusterMonitor).
          # Idempotent, uses the existing root password — no new secret. Reusing
          # root keeps this simple; a dedicated least-privilege user would need
          # its own credential.
          mongodb-exporter-grant = {
            description = "Grant clusterMonitor to the MongoDB root user for the exporter";

            after = ["mongodb.service"];
            requires = ["mongodb.service"];
            wantedBy = ["multi-user.target"];
            before = ["prometheus-mongodb-exporter.service"];

            path = [pkgs.mongosh];

            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              User = "mongodb";
              Group = "mongodb";
            };

            script = ''
              set -euo pipefail
              pw="$(<${config.sops.secrets."mongodb/root-password".path})"

              # Wait for mongod to accept authenticated connections.
              until mongosh --quiet --host 127.0.0.1 --port 27017 \
                -u root -p "$pw" --authenticationDatabase admin \
                --eval 'db.runCommand({ ping: 1 })' >/dev/null 2>&1; do
                sleep 0.5
              done

              mongosh --quiet --host 127.0.0.1 --port 27017 \
                -u root -p "$pw" --authenticationDatabase admin admin \
                --eval 'db.grantRolesToUser("root", [{ role: "clusterMonitor", db: "admin" }])'
            '';
          };
        };
      })
    ];

    users = {
      users = {
        mongodb = {
          uid = cfg.userId;
        };
      };

      groups = {
        mongodb = {
          gid = cfg.groupId;
        };
      };
    };

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = cfg.zfs.enable;
      directories = [cfg.dataDir];
    };
  };
}
