{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.mongodb;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.mongodb = lib.mkIf cfg.zfs.enable {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = cfg.dataDir;
      requiredBy = ["mongodb.service"];

      restic = {
        enable = true;
      };
    };

    services = {
      mongodb = {
        inherit (cfg) enable;

        dbpath = cfg.dataDir;
        enableAuth = true;
        initialRootPasswordFile = config.sops.secrets."mongodb/root-password".path;
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        mongodb = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };

            requires = ["mongodb-permissions.service"];
            after = ["mongodb-permissions.service"];
          }

          (lib.mkIf cfg.zfs.enable {
            requires = ["zfs-dataset-mongodb.service"];
            after = ["zfs-dataset-mongodb.service"];
          })
        ];

        mongodb-permissions = {
          description = "Fix MongoDB dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = [
            "mongodb.service"
          ];
          after =
            ["local-fs.target"]
            ++ lib.optionals cfg.zfs.enable ["zfs-dataset-mongodb.service"];
          requires =
            lib.optionals cfg.zfs.enable ["zfs-dataset-mongodb.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown mongodb:mongodb ${cfg.dataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${cfg.dataDir} 0700 mongodb mongodb -"
        "z ${cfg.dataDir} 0700 mongodb mongodb -"
      ];
    };

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

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !cfg.zfs.enable
      )
      {
        persistence."/nix/persist".directories = [
          cfg.dataDir
        ];
      };
  };
}
