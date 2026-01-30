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
            ["local-fs.target"]
            ++ lib.optionals cfg.zfs.enable [
              "zfs-dataset-opencloud-root.service"
              "zfs-dataset-opencloud-etc.service"
              "zfs-dataset-opencloud-idm.service"
              "zfs-dataset-opencloud-nats.service"
              "zfs-dataset-opencloud-search.service"
              "zfs-dataset-opencloud-storage.service"
              "zfs-dataset-opencloud-storage-metadata.service"
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
            "zfs-dataset-opencloud-storage-users.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown -R opencloud:opencloud ${toString cfg.dataDir}
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
            "podman-opencloud-wopi.service"
          ];

          requires = [
            "opencloud-permissions.service"
            "zfs-dataset-opencloud-etc.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
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
        "z ${toString cfg.dataDir} 0750 opencloud opencloud -"
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
