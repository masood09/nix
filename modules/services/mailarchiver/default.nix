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
            Enabled = true;
            Authority = cfg.oauth.issuerURL;
            ClientId = cfg.oauth.clientID;
            DisablePasswordLogin = true;
            AutoRedirect = true;
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

    # Service hardening + mount ordering
    systemd = {
      services = {
        mailarchiver-permissions = {
          description = "Fix MailArchiver dataDir ownership/permissions";
          wantedBy = ["mailarchiver.service"];
          before = ["mailarchiver.service"];

          after =
            ["systemd-tmpfiles-setup.service" "local-fs.target"]
            ++ lib.optionals cfg.zfs.enable [
              "zfs-dataset-mailarchiver.service"
            ];
          requires = lib.optionals cfg.zfs.enable [
            "zfs-dataset-mailarchiver.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown mailarchiver:mailarchiver \
                ${toString cfg.dataDir}
            '';
          };
        };

        "mailarchiver" = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };
          }

          (lib.mkIf cfg.zfs.enable {
            requires =
              [
                "zfs-dataset-mailarchiver.service"
              ]
              ++ lib.optionals postgresqlEnabled [
                "postgresql.target"
              ];

            after =
              [
                "zfs-dataset-mailarchiver.service"
              ]
              ++ lib.optionals postgresqlEnabled [
                "postgresql.target"
              ];
          })
        ];
      };

      tmpfiles.rules = [
        "d ${toString cfg.dataDir} 0750 mailarchiver mailarchiver -"
      ];
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
