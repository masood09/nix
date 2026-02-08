{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.matrix-synapse;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    homelab.zfs.datasets = lib.mkIf cfg.zfs.enable {
      matrix-synapse = {
        enable = true;

        inherit (cfg.zfs.dataDir) dataset properties;

        mountpoint = cfg.dataDir;
        requiredBy = ["matrix-synapse.service"];

        restic = {
          enable = true;
        };
      };

      matrix-synapse-media = {
        enable = true;

        inherit (cfg.zfs.mediaDir) dataset properties;

        mountpoint = cfg.mediaDir;
        requiredBy = ["matrix-synapse.service"];

        restic = {
          enable = true;
        };
      };
    };

    services = {
      matrix-synapse = {
        enable = true;

        inherit (cfg) dataDir;

        settings = {
          media_store_path = cfg.mediaDir;
          server_name = cfg.serverName;
          public_baseurl = cfg.webDomain;

          listeners = [
            {
              port = cfg.listenPort;
              bind_addresses = cfg.listenAddress;
              type = "http";
              tls = false;
              x_forwarded = true;
              resources = [
                {
                  names = [
                    "client"
                    "federation"
                  ];
                  compress = true;
                }
              ];
            }
          ];
        };
      };
    };

    systemd = {
      services = {
        matrix-synapse-permissions = {
          description = "Fix Matrix Synapse dataDir ownership/permissions";
          wantedBy = ["matrix-synapse.service"];
          before = ["matrix-synapse.service"];

          after =
            ["systemd-tmpfiles-setup.service" "local-fs.target"]
            ++ lib.optionals cfg.zfs.enable [
              "zfs-dataset-matrix-synapse.service"
              "zfs-dataset-matrix-synapse-media.service"
            ];
          requires = lib.optionals cfg.zfs.enable [
            "zfs-dataset-matrix-synapse.service"
            "zfs-dataset-matrix-synapse-media.service"
          ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown matrix-synapse:matrix-synapse \
                ${toString cfg.dataDir} \
                ${toString cfg.mediaDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        "d ${toString cfg.dataDir} 0750 matrix-synapse matrix-synapse -"
        "d ${toString cfg.mediaDir} 0750 matrix-synapse matrix-synapse -"
        "z ${toString cfg.dataDir} 0750 matrix-synapse matrix-synapse -"
        "z ${toString cfg.mediaDir} 0750 matrix-synapse matrix-synapse -"
      ];
    };
  };
}
