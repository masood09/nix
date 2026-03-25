# MailArchiver — email archival service with OAuth login via Authentik.
# Backed by PostgreSQL with ZFS dataset for persistent storage.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.mailarchiver;
  caddyEnabled = config.services.caddy.enable;
  postgresqlEnabled = config.services.postgresql.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "mailarchiver";
    inherit (cfg) dataDir;
    user = "mailarchiver";
    group = "mailarchiver";
    mode = "0750";
    mainServices = ["mailarchiver"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-mailarchiver";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = postgresqlEnabled;
        message = "MailArchiver requires PostgreSQL (homelab.services.postgresql.enable)";
      }
    ];
    # ZFS dataset for dataDir
    homelab = {
      zfs = {
        datasets = {
          mailarchiver = lib.mkIf cfg.zfs.enable {
            inherit (cfg.zfs) dataset properties;

            enable = true;
            mountpoint = cfg.dataDir;

            requiredBy = [
              "mailarchiver.service"
            ];

            restic = {
              enable = true;
            };
          };
        };
      };
    };

    services = {
      mailarchiver = {
        enable = true;

        inherit (cfg) dataDir listenAddress port;

        environmentFile = config.sops.secrets."mailarchiver/.env".path;

        settings = {
          TimeZone = {
            DisplayTimeZoneId = config.time.timeZone;
          };

          OAuth = {
            Enabled = cfg.oauth.enable;
            Authority = cfg.oauth.issuerURL;
            ClientId = cfg.oauth.clientID;
            DisablePasswordLogin = cfg.oauth.disablePasswordLogin;
            AutoRedirect = cfg.oauth.autoRedirect;
            AutoApproveUsers = true;
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.port}
            '';
          };
        };
      };

      postgresql = lib.mkIf postgresqlEnabled {
        ensureDatabases = [
          "mailarchiver"
        ];

        ensureUsers = [
          {
            name = "mailarchiver";
            ensureDBOwnership = true;
          }
        ];
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled) {
        databases = [
          "mailarchiver"
        ];
      };
    };

    systemd = lib.mkMerge [
      permSvc.systemd

      # PostgreSQL ordering (separate from permission service concerns)
      (lib.mkIf postgresqlEnabled {
        services = {
          mailarchiver = {
            requires = ["postgresql.target"];
            after = ["postgresql.target"];
          };
        };
      })
    ];

    users = {
      users = {
        mailarchiver = {
          isSystemUser = true;
          group = "mailarchiver";
          uid = cfg.userId;
        };
      };

      groups = {
        mailarchiver = {
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
