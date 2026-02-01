{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  vaultwardenCfg = homelabCfg.services.vaultwarden;
  caddyEnabled = config.services.caddy.enable;
  postgresqlEnabled = config.services.postgresql.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;
  resticEnabled = config.homelab.services.restic.enable;
in {
  options.homelab.services.vaultwarden = {
    enable = lib.mkEnableOption "Whether to enable Vaultwarden.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "passwords.mantannest.com";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/vaultwarden/";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 8222;
      type = lib.types.port;
    };

    userId = lib.mkOption {
      default = 3003;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3003;
      type = lib.types.ints.u16;
    };

    zfs = {
      enable = lib.mkEnableOption "Store Vaultwarden dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/vaultwarden";
        description = "ZFS dataset to create and mount at dataDir.";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
        };
        description = "ZFS properties for the dataset.";
      };
    };
  };

  config = lib.mkIf vaultwardenCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.vaultwarden = lib.mkIf vaultwardenCfg.zfs.enable {
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

    services = {
      vaultwarden = {
        enable = true;
        dbBackend =
          if postgresqlEnabled
          then "postgresql"
          else "sqlite";
        environmentFile = config.sops.secrets."vaultwarden.env".path;

        config = {
          DOMAIN = "https://${vaultwardenCfg.webDomain}";
          ROCKET_ADDRESS = vaultwardenCfg.listenAddress;
          ROCKET_PORT = vaultwardenCfg.listenPort;
        };
      };

      restic = lib.mkIf (resticEnabled && vaultwardenCfg.zfs.enable) {
        backups = {
          s3-backup.exclude = [
            "/mnt/nightly_backup/vaultwarden/tmp"
          ];
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${vaultwardenCfg.webDomain}" = {
            useACMEHost = vaultwardenCfg.webDomain;
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

    security = lib.mkIf (caddyEnabled && vaultwardenCfg.enable) {
      acme.certs."${vaultwardenCfg.webDomain}".domain = "${vaultwardenCfg.webDomain}";
    };

    users.users = {
      vaultwarden.uid = vaultwardenCfg.userId;
    };

    users.groups = {
      vaultwarden.gid = vaultwardenCfg.groupId;
    };

    # Service hardening + mount ordering
    systemd = {
      services.vaultwarden = lib.mkMerge [
        {
          # Unit-level ordering / mount requirements
          unitConfig = {
            RequiresMountsFor = [vaultwardenCfg.dataDir];
          };
        }

        (lib.mkIf vaultwardenCfg.zfs.enable {
          requires = ["zfs-dataset-vaultwarden.service"];
          after = ["zfs-dataset-vaultwarden.service"];
        })
      ];

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${vaultwardenCfg.dataDir} 0700 vaultwarden vaultwarden -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !vaultwardenCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          vaultwardenCfg.dataDir
        ];
      };
  };
}
