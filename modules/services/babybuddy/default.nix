{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  babybuddyCfg = homelabCfg.services.babybuddy;
  podmanEnabled = homelabCfg.services.podman.enable;
  caddyEnabled = config.services.caddy.enable;
  postgresqlEnabled = config.services.postgresql.enable;
  postgresqlBackupEnabled = config.services.postgresqlBackup.enable;
  resticEnabled = config.homelab.services.restic.enable;
in {
  options.homelab.services.babybuddy = {
    enable = lib.mkEnableOption "Whether to enable Baby Buddy.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "babybuddy.homelab.mantannest.com";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/babybuddy";
    };

    listenAddress = lib.mkOption {
      default = "127.0.0.1";
      type = lib.types.str;
    };

    listenPort = lib.mkOption {
      default = 8804;
      type = lib.types.port;
    };

    userId = lib.mkOption {
      default = 3004;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3004;
      type = lib.types.ints.u16;
    };

    zfs = {
      enable = lib.mkEnableOption "Store Baby Buddy dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/babybuddy";
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

  config = lib.mkIf (babybuddyCfg.enable && podmanEnabled) {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.babybuddy = lib.mkIf babybuddyCfg.zfs.enable {
      inherit (babybuddyCfg.zfs) dataset properties;

      enable = true;
      mountpoint = babybuddyCfg.dataDir;

      requiredBy = [
        "podman-babybuddy.service"
      ];

      restic = {
        enable = true;
      };
    };

    virtualisation.oci-containers.containers.babybuddy = {
      image = "lscr.io/linuxserver/babybuddy:2.7.1";
      autoStart = true;

      extraOptions = [
        "--cap-add=CAP_NET_RAW"
      ];

      volumes = [
        "${toString babybuddyCfg.dataDir}:/config"
      ];

      ports = [
        "${babybuddyCfg.listenAddress}:${toString babybuddyCfg.listenPort}:8000"
      ];

      environment = {
        TZ = config.time.timeZone;
        PUID = toString babybuddyCfg.userId;
        PGID = toString babybuddyCfg.groupId;
        ALLOWED_HOSTS = babybuddyCfg.webDomain;
        SESSION_COOKIE_SECURE = "True";
        CSRF_COOKIE_SECURE = "True";
        CSRF_TRUSTED_ORIGINS = "https://${babybuddyCfg.webDomain}";
        CORS_ALLOWED_ORIGINS = "https://${babybuddyCfg.webDomain}";
      };

      environmentFiles = [
        config.sops.secrets."babybuddy-env".path
      ];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${babybuddyCfg.webDomain}" = {
            useACMEHost = babybuddyCfg.webDomain;
            extraConfig = ''
              reverse_proxy http://${babybuddyCfg.listenAddress}:${toString babybuddyCfg.listenPort}
            '';
          };
        };
      };

      restic = lib.mkIf (resticEnabled && babybuddyCfg.zfs.enable) {
        backups = {
          s3-backup.exclude = [
            "/mnt/nightly_backup/babybuddy/keys"
            "/mnt/nightly_backup/babybuddy/log"
            "/mnt/nightly_backup/babybuddy/nginx"
            "/mnt/nightly_backup/babybuddy/php"
            "/mnt/nightly_backup/babybuddy/www"
          ];
        };
      };

      postgresql = lib.mkIf postgresqlEnabled {
        ensureDatabases = [
          "babybuddy"
        ];

        ensureUsers = [
          {
            name = "babybuddy";
            ensureDBOwnership = true;
          }
        ];
      };

      postgresqlBackup = lib.mkIf (postgresqlEnabled && postgresqlBackupEnabled) {
        databases = [
          "babybuddy"
        ];
      };
    };

    security = lib.mkIf (caddyEnabled && babybuddyCfg.enable) {
      acme.certs."${babybuddyCfg.webDomain}".domain = "${babybuddyCfg.webDomain}";
    };

    users = {
      users = {
        babybuddy = {
          isSystemUser = true;
          group = "babybuddy";
          uid = babybuddyCfg.userId;
        };
      };

      groups = {
        babybuddy = {
          gid = babybuddyCfg.groupId;
        };
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services.podman-babybuddy = lib.mkMerge [
        {
          # Unit-level ordering / mount requirements
          unitConfig = {
            RequiresMountsFor = [babybuddyCfg.dataDir];
          };
        }

        (lib.mkIf babybuddyCfg.zfs.enable {
          requires = ["zfs-dataset-babybuddy.service"];
          after = ["zfs-dataset-babybuddy.service"];
        })
      ];

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${babybuddyCfg.dataDir} 0750 babybuddy babybuddy -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !babybuddyCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          babybuddyCfg.dataDir
        ];
      };
  };
}
