{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.karakeep;
  caddyEnabled = config.services.caddy.enable;
in {
  imports = [
    ./options.nix
  ];

  config = lib.mkIf cfg.enable {
    # ZFS dataset for dataDir
    homelab.zfs.datasets.karakeep = lib.mkIf cfg.zfs.enable {
      inherit (cfg.zfs) dataset properties;

      enable = true;
      mountpoint = cfg.dataDir;

      requiredBy = [
        "karakeep.service"
      ];

      restic = {
        enable = true;
      };
    };

    services = {
      karakeep = {
        enable = true;

        environmentFile = config.sops.secrets."karakeep.env".path;

        extraEnvironment = {
          PORT = toString cfg.listenPort;
          DISABLE_NEW_RELEASE_CHECK = "true";

          NEXTAUTH_URL = "https://${cfg.webDomain}";

          OAUTH_CLIENT_ID = cfg.oauth.clientId;
          OAUTH_WELLKNOWN_URL = "https://${cfg.oauth.providerHost}/application/o/karakeep/.well-known/openid-configuration";
          OAUTH_PROVIDER_NAME = "authentik";
          OAUTH_ALLOW_DANGEROUS_EMAIL_ACCOUNT_LINKING = "true";
          DISABLE_PASSWORD_AUTH = "true";

          INFERENCE_CONTEXT_LENGTH = "16384";
          INFERENCE_MAX_OUTPUT_TOKENS = "16384";
          INFERENCE_ENABLE_AUTO_SUMMARIZATION = "true";
        };
      };

      meilisearch = {
        settings = {
          no_analytics = true;
        };
      };

      caddy = lib.mkIf caddyEnabled {
        virtualHosts = {
          "${cfg.webDomain}" = {
            useACMEHost = config.networking.domain;

            extraConfig = ''
              reverse_proxy http://127.0.0.1:${toString cfg.listenPort}
            '';
          };
        };
      };
    };

    users = {
      users = {
        karakeep = {
          isSystemUser = true;
          group = "karakeep";
          uid = cfg.userId;
        };
      };

      groups = {
        karakeep = {
          gid = cfg.groupId;
        };
      };
    };

    # Service hardening + mount ordering
    systemd = {
      services = {
        karakeep-init = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };

            requires = ["karakeep-permissions.service"];
            after = ["karakeep-permissions.service"];
          }

          (lib.mkIf cfg.zfs.enable {
            requires = ["zfs-dataset-karakeep.service"];
            after = ["zfs-dataset-karakeep.service"];
          })
        ];

        karakeep-workers = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };

            requires = ["karakeep-permissions.service"];
            after = ["karakeep-permissions.service"];
          }

          (lib.mkIf cfg.zfs.enable {
            requires = ["zfs-dataset-karakeep.service"];
            after = ["zfs-dataset-karakeep.service"];
          })
        ];

        karakeep-web = lib.mkMerge [
          {
            # Unit-level ordering / mount requirements
            unitConfig = {
              RequiresMountsFor = [cfg.dataDir];
            };

            requires = ["karakeep-permissions.service"];
            after = ["karakeep-permissions.service"];
          }

          (lib.mkIf cfg.zfs.enable {
            requires = ["zfs-dataset-karakeep.service"];
            after = ["zfs-dataset-karakeep.service"];
          })
        ];

        karakeep-permissions = {
          description = "Fix Karakeep dataDir ownership/permissions";
          wantedBy = ["multi-user.target"];
          before = [
            "karakeep-init.service"
            "karakeep-workers.service"
            "karakeep-web.service"
          ];
          after =
            ["local-fs.target"]
            ++ lib.optionals cfg.zfs.enable ["zfs-dataset-karakeep.service"];
          requires =
            lib.optionals cfg.zfs.enable ["zfs-dataset-karakeep.service"];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = ''
              ${pkgs.coreutils}/bin/chown -R karakeep:karakeep ${cfg.dataDir}
            '';
          };
        };
      };

      tmpfiles.rules = [
        # Ensure base dir exists and is owned correctly
        "d ${cfg.dataDir} 0700 karakeep karakeep -"
        "z ${cfg.dataDir} 0700 karakeep karakeep -"
      ];
    };

    environment =
      lib.mkIf (
        homelabCfg.impermanence
        && !homelabCfg.isRootZFS
        && !cfg.zfs.enable
      ) {
        persistence."/nix/persist".directories = [
          cfg.dataDir
        ];
      };
  };
}
