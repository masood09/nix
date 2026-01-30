{
  config,
  lib,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.opencloud;
  podmanEnabled = homelabCfg.services.podman.enable;
in {
  config = lib.mkIf (cfg.enable && podmanEnabled) {
    homelab.zfs.datasets = lib.mkMerge [
      (lib.mkIf cfg.zfs.enable {
        opencloud-root = {
          enable = true;
          dataset = cfg.zfs.rootDataset;
          mountpoint = cfg.dataDir;
          restic.enable = false;

          requiredBy = [
            "zfs-dataset-opencloud-etc.service"
            "zfs-dataset-opencloud-idm.service"
            "zfs-dataset-opencloud-nats.service"
            "zfs-dataset-opencloud-search.service"
            "zfs-dataset-opencloud-storage.service"
            "zfs-dataset-opencloud-storage-metadata.service"
            "zfs-dataset-opencloud-storage-users.service"
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
          ];
        };

        opencloud-etc = {
          enable = true;
          dataset = cfg.zfs.etcDataset;
          mountpoint = cfg.dataDir + "/etc";
          restic.enable = true;
          properties = cfg.zfs.etcProperties;

          requiredBy = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
          ];
        };

        opencloud-idm = {
          enable = true;
          dataset = cfg.zfs.idmDataset;
          mountpoint = cfg.dataDir + "/idm";
          restic.enable = true;
          properties = cfg.zfs.idmProperties;

          requiredBy = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
          ];
        };

        opencloud-nats = {
          enable = true;
          dataset = cfg.zfs.natsDataset;
          mountpoint = cfg.dataDir + "/nats";
          restic.enable = false;
          properties = cfg.zfs.natsProperties;

          requiredBy = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
          ];
        };

        opencloud-search = {
          enable = true;
          dataset = cfg.zfs.searchDataset;
          mountpoint = cfg.dataDir + "/search";
          restic.enable = false;
          properties = cfg.zfs.searchProperties;

          requiredBy = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
          ];
        };

        opencloud-storage = {
          enable = true;
          dataset = cfg.zfs.rootDataset + "/storage";
          mountpoint = cfg.dataDir + "/storage";
          restic.enable = false;

          requiredBy = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
            "zfs-dataset-opencloud-storage-metadata.service"
            "zfs-dataset-opencloud-storage-users.service"
          ];
        };

        opencloud-storage-metadata = {
          enable = true;
          dataset = cfg.zfs.storageMetaDataset;
          mountpoint = cfg.dataDir + "/storage/metadata";
          restic.enable = true;
          properties = cfg.zfs.storageMetaProperties;

          requiredBy = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
          ];
        };

        opencloud-storage-users = {
          enable = true;
          dataset = cfg.zfs.userStorageDataset;
          mountpoint = cfg.dataDir + "/storage/users";
          restic.enable = true;
          properties = cfg.zfs.userStorageProperties;

          requiredBy = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-collabora.service"
          ];
        };
      })
    ];
  };
}
