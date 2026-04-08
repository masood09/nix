# Vaultwarden — self-hosted Bitwarden-compatible password manager.
# Optional SSO login via Authentik. Uses PostgreSQL when available,
# falls back to SQLite otherwise.
{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  vaultwardenCfg = homelabCfg.services.vaultwarden;
  caddyEnabled = config.services.caddy.enable;
  postgresqlEnabled = config.services.postgresql.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;
  resticEnabled = config.homelab.services.restic.enable;

  persistenceHelpers = import ../../../lib/persistence-helpers.nix {inherit lib;};
  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "vaultwarden";
    inherit (vaultwardenCfg) dataDir;
    user = "vaultwarden";
    group = "vaultwarden";
    mainServices = ["vaultwarden"];
    zfs = {
      inherit (vaultwardenCfg.zfs) enable;
      datasetServiceName = "zfs-dataset-vaultwarden";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf vaultwardenCfg.enable {
    # ZFS dataset for dataDir
    homelab = {
      zfs = {
        datasets = {
          vaultwarden = lib.mkIf vaultwardenCfg.zfs.enable {
            inherit (vaultwardenCfg.zfs) dataset properties;

            enable = true;
            mountpoint = vaultwardenCfg.dataDir;

            requiredBy = [
              "vaultwarden.service"
            ];

            restic = {
              enable = true;
            };
          };
        };
      };
    };

    services = {
      vaultwarden = {
        enable = true;
        dbBackend =
          if postgresqlEnabled
          then "postgresql"
          else "sqlite";
        environmentFile = config.sops.secrets."vaultwarden/.env".path;

        config =
          {
            DOMAIN = "https://${vaultwardenCfg.webDomain}";
            ROCKET_ADDRESS = vaultwardenCfg.listenAddress;
            ROCKET_PORT = vaultwardenCfg.listenPort;
          }
          // lib.optionalAttrs vaultwardenCfg.oauth.enable {
            SSO_ENABLED = "true";
            SSO_AUTHORITY = "https://${vaultwardenCfg.oauth.providerHost}/application/o/vaultwarden/";
            SSO_CLIENT_ID = vaultwardenCfg.oauth.clientId;
            SSO_SCOPES = "email profile offline_access";
            SSO_ALLOW_UNKNOWN_EMAIL_VERIFICATION = "false";
            SSO_CLIENT_CACHE_EXPIRATION = 0;
            SSO_ONLY = "true";
            SSO_SIGNUPS_MATCH_EMAIL = "true";
          };
      };

      restic = lib.mkIf (resticEnabled && vaultwardenCfg.zfs.enable) {
        backups = {
          backup = {
            exclude = [
              "/mnt/nightly_backup/vaultwarden/tmp"
            ];
          };
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${vaultwardenCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://${vaultwardenCfg.listenAddress}:${toString vaultwardenCfg.listenPort}
            '';
          };
        };
      };

      postgresql = lib.mkIf postgresqlEnabled {
        ensureDatabases = [
          "vaultwarden"
        ];

        ensureUsers = [
          {
            name = "vaultwarden";
            ensureDBOwnership = true;
          }
        ];
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled) {
        databases = [
          "vaultwarden"
        ];
      };
    };

    users = {
      users = {
        vaultwarden = {
          uid = vaultwardenCfg.userId;
        };
      };

      groups = {
        vaultwarden = {
          gid = vaultwardenCfg.groupId;
        };
      };
    };

    inherit (permSvc) systemd;

    environment = persistenceHelpers.mkPersistenceDirs {
      inherit homelabCfg;
      zfsEnable = vaultwardenCfg.zfs.enable;
      directories = [vaultwardenCfg.dataDir];
    };

    networking = {
      firewall = lib.mkIf vaultwardenCfg.openFirewall {
        allowedTCPPorts = [
          vaultwardenCfg.listenPort
        ];
      };
    };
  };
}
