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
in {
  imports = [
    ./options.nix
  ];

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
        environmentFile = config.sops.secrets."vaultwarden/.env".path;

        config = {
          DOMAIN = "https://${vaultwardenCfg.webDomain}";
          ROCKET_ADDRESS = vaultwardenCfg.listenAddress;
          ROCKET_PORT = vaultwardenCfg.listenPort;
        };
      };

      restic = lib.mkIf (resticEnabled && vaultwardenCfg.zfs.enable) {
        backups = {
          backup.exclude = [
            "/mnt/nightly_backup/vaultwarden/tmp"
          ];
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

    users.users = {
      vaultwarden.uid = vaultwardenCfg.userId;
    };

    users.groups = {
      vaultwarden.gid = vaultwardenCfg.groupId;
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        vaultwarden = lib.mkMerge [
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

        vaultwarden-permissions = {
          description = "Fix Vaultwarden dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["vaultwarden.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals vaultwardenCfg.zfs.enable ["zfs-dataset-vaultwarden.service"];
          requires =
            lib.optionals vaultwardenCfg.zfs.enable ["zfs-dataset-vaultwarden.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown vaultwarden:vaultwarden ${vaultwardenCfg.dataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${vaultwardenCfg.dataDir} 0700 vaultwarden vaultwarden -"
        "z ${vaultwardenCfg.dataDir} 0700 vaultwarden vaultwarden -"
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
