{
  config,
  lib,
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
    systemd.services = {
      mongodb = lib.mkMerge [
        {
          # Unit-level ordering / mount requirements
          unitConfig = {
            RequiresMountsFor = [cfg.dataDir];
          };
        }

        (lib.mkIf cfg.zfs.enable {
          requires = ["zfs-dataset-mongodb.service"];
          after = ["zfs-dataset-mongodb.service"];
        })
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
