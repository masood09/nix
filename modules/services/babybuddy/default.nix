{
  config,
  lib,
  pkgs,
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
  imports = [
    ./options.nix
  ];

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
      # renovate: datasource=docker depName=lscr.io/linuxserver/babybuddy
      image = "lscr.io/linuxserver/babybuddy:2.7.1";
      autoStart = true;

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
        config.sops.secrets."babybuddy.env".path
      ];
    };

    services = {
      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${babybuddyCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://${babybuddyCfg.listenAddress}:${toString babybuddyCfg.listenPort}
            '';
          };
        };
      };

      restic = lib.mkIf (resticEnabled && babybuddyCfg.zfs.enable) {
        backups = {
          backup.exclude = [
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
      services = {
        babybuddy-permissions = {
          description = "Fix Babybuddy dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];

          after =
            ["local-fs.target"]
            ++ lib.optionals babybuddyCfg.zfs.enable [
              "zfs-dataset-babybuddy.service"
            ];
          requires = lib.optionals babybuddyCfg.zfs.enable [
            "zfs-dataset-babybuddy.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown babybuddy:babybuddy ${toString babybuddyCfg.dataDir}
            '';
          };
        };

        podman-babybuddy = lib.mkMerge [
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
      };

      tmpfiles.rules = [
        "d ${babybuddyCfg.dataDir} 0750 babybuddy babybuddy -"
        "z ${babybuddyCfg.dataDir} 0750 babybuddy babybuddy -"
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
