{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.mongodb;

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "mongodb";
    inherit (cfg) dataDir;
    user = "mongodb";
    group = "mongodb";
    mainServices = ["mongodb"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-mongodb";
    };
  };
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

    inherit (permSvc) systemd;

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
