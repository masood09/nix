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

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "mailarchiver";
    dataDir = cfg.dataDir;
    user = "mailarchiver";
    group = "mailarchiver";
    mode = "0750";
    mainServices = ["mailarchiver"];
    zfs = {
      enable = cfg.zfs.enable;
      datasetServiceName = "zfs-dataset-mailarchiver";
    };
  };
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets = {
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

    services = {
      mailarchiver = {
        enable = true;

        inherit (cfg) dataDir listenAddress port;

        environmentFile = config.sops.secrets."mailarchiver/.env".path;

        settings = {
          TimeZone.DisplayTimeZoneId = config.time.timeZone;

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

    inherit (permSvc) systemd;

    # PostgreSQL ordering (separate from permission service concerns)
    systemd.services.mailarchiver = lib.mkIf postgresqlEnabled {
      requires = ["postgresql.target"];
      after = ["postgresql.target"];
    };

    users = {
      users.mailarchiver = {
        uid = cfg.userId;
      };

      groups.mailarchiver = {
        gid = cfg.groupId;
      };
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
      ) {
        persistence."/nix/persist".directories = lib.optionals (!cfg.zfs.enable) [
          cfg.dataDir
        ];
      };
  };
}
