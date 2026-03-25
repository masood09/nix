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
in {
  imports = [
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
