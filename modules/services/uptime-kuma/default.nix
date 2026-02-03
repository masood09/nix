{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  uptimeKumaCfg = homelabCfg.services.uptime-kuma;
  caddyEnabled = homelabCfg.services.caddy.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf uptimeKumaCfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.uptime-kuma = lib.mkIf uptimeKumaCfg.zfs.enable {
      inherit (uptimeKumaCfg.zfs) dataset properties;

      enable = true;
      mountpoint = uptimeKumaCfg.dataDir;
      requiredBy = ["uptime-kuma.service"];

      restic = {
        enable = true;
      };
    };

    services = {
      uptime-kuma = {
        inherit (uptimeKumaCfg) enable;

        settings = {
          DATA_DIR = uptimeKumaCfg.dataDir;
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${uptimeKumaCfg.webDomain}" = {
            useACMEHost = config.networking.domain;
            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString config.services.uptime-kuma.settings.PORT}
            '';
          };
        };
      };
    };

    users = {
      users = {
        uptime-kuma = {
          isSystemUser = true;
          group = "uptime-kuma";
          uid = uptimeKumaCfg.userId;
        };
      };

      groups = {
        uptime-kuma = {
          gid = uptimeKumaCfg.groupId;
        };
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        uptime-kuma = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [uptimeKumaCfg.dataDir];
            };

            serviceConfig = {
              DynamicUser = lib.mkForce false;

              # stop systemd from trying to manage /var/lib/private + bind-mount behavior
              StateDirectory = lib.mkForce null;
              StateDirectoryMode = lib.mkForce null;

              User = "uptime-kuma";
              Group = "uptime-kuma";

              # with ProtectSystem=strict, you must explicitly allow writes here
              ReadWritePaths = [uptimeKumaCfg.dataDir];
            };
          }

          (lib.mkIf uptimeKumaCfg.zfs.enable {
            requires = ["zfs-dataset-uptime-kuma.service"];
            after = ["zfs-dataset-uptime-kuma.service"];
          })
        ];

        uptime-kuma-permissions = {
          description = "Fix Uptime Kuma dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = ["uptime-kuma.service"];
          after =
            ["local-fs.target"]
            ++ lib.optionals uptimeKumaCfg.zfs.enable ["zfs-dataset-uptime-kuma.service"];
          requires =
            lib.optionals uptimeKumaCfg.zfs.enable ["zfs-dataset-uptime-kuma.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown uptime-kuma:uptime-kuma ${uptimeKumaCfg.dataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${uptimeKumaCfg.dataDir} 0750 uptime-kuma uptime-kuma -"
        "z ${uptimeKumaCfg.dataDir} 0750 uptime-kuma uptime-kuma -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !uptimeKumaCfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          uptimeKumaCfg.dataDir
        ];
      };
  };
}
