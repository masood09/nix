{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.opencloud;
  podmanEnabled = homelabCfg.services.podman.enable;

  proxySrc = ./config/proxy.yaml;
  cspSrc = ./config/csp.yaml;
in {
  config = lib.mkIf (cfg.enable && podmanEnabled) {
    systemd = {
      services = {
        opencloud-permissions = {
          description = "Fix OpenCloud dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];

          after =
            ["systemd-tmpfiles-setup.service" "local-fs.target"]
            ++ lib.optionals cfg.zfs.enable [
              "zfs-dataset-opencloud-root.service"
              "zfs-dataset-opencloud-etc.service"
              "zfs-dataset-opencloud-idm.service"
              "zfs-dataset-opencloud-nats.service"
              "zfs-dataset-opencloud-search.service"
              "zfs-dataset-opencloud-storage.service"
              "zfs-dataset-opencloud-storage-metadata.service"
              "zfs-dataset-opencloud-storage-ocm.service"
              "zfs-dataset-opencloud-storage-users.service"
            ];
          requires = lib.optionals cfg.zfs.enable [
            "zfs-dataset-opencloud-root.service"
            "zfs-dataset-opencloud-etc.service"
            "zfs-dataset-opencloud-idm.service"
            "zfs-dataset-opencloud-nats.service"
            "zfs-dataset-opencloud-search.service"
            "zfs-dataset-opencloud-storage.service"
            "zfs-dataset-opencloud-storage-metadata.service"
            "zfs-dataset-opencloud-storage-ocm.service"
            "zfs-dataset-opencloud-storage-users.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown opencloud:opencloud \
                ${toString cfg.dataDir} \
                ${toString cfg.dataDir}/etc \
                ${toString cfg.dataDir}/idm \
                ${toString cfg.dataDir}/nats \
                ${toString cfg.dataDir}/search \
                ${toString cfg.dataDir}/storage \
                ${toString cfg.dataDir}/storage/metadata \
                ${toString cfg.dataDir}/storage/ocm \
                ${toString cfg.dataDir}/storage/users
            '';
          };
        };

        opencloud-sync-etc = {
          description = "Materialize OpenCloud proxy.yaml and csp.yaml into ${cfg.dataDir}/etc";
          wantedBy = ["multi-user.target"];

          after = [
            "opencloud-permissions.service"
            "zfs-dataset-opencloud-etc.service"
          ];

          before = [
            "podman-compose-opencloud-root.service"
            "podman-opencloud-opencloud.service"
            "podman-opencloud-wopi.service"
          ];

          requires = [
            "opencloud-permissions.service"
            "zfs-dataset-opencloud-etc.service"
          ];

          serviceConfig = {
            Type = "oneshot";
          };

          script = ''
            set -euo pipefail
            install -d -m 0750 -o opencloud -g opencloud ${cfg.dataDir}/etc

            # install copies and sets perms atomically
            install -m 0600 -o opencloud -g opencloud ${proxySrc} ${cfg.dataDir}/etc/proxy.yaml
            install -m 0600 -o opencloud -g opencloud ${cspSrc} ${cfg.dataDir}/etc/csp.yaml
          '';
        };
      };

      tmpfiles.rules = [
        "d ${toString cfg.dataDir} 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/etc 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/idm 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/nats 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/search 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/storage 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/storage/metadata 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/storage/ocm 0750 opencloud opencloud -"
        "d ${toString cfg.dataDir}/storage/users 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir} 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/etc 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/idm 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/nats 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/search 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/storage 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/storage/metadata 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/storage/ocm 0750 opencloud opencloud -"
        "z ${toString cfg.dataDir}/storage/users 0750 opencloud opencloud -"
      ];
    };

    # Impermanence fallback if you ever disable ZFS datasets
    environment = lib.mkIf (homelabCfg.impermanence && !cfg.zfs.enable) {
      persistence."/nix/persist".directories = [
        cfg.dataDir
      ];
    };
  };
}
