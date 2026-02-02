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
  options.homelab.services.karakeep = {
    enable = lib.mkEnableOption "Whether to enable Karakeep.";

    webDomain = lib.mkOption {
      type = lib.types.str;
      default = "keep.mantannest.com";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/karakeep/";
    };

    listenPort = lib.mkOption {
      default = 8904;
      type = lib.types.port;
    };

    userId = lib.mkOption {
      default = 3007;
      type = lib.types.ints.u16;
    };

    groupId = lib.mkOption {
      default = 3007;
      type = lib.types.ints.u16;
    };

    oauth = {
      providerHost = lib.mkOption {
        type = lib.types.str;
        default = "auth.mantannest.com";
      };

      clientId = lib.mkOption {
        type = lib.types.str;
        default = "LMIokPsj1HsqybAQGh6JOVpF33ChM6eS0EE2JYG0";
      };
    };

    zfs = {
      enable = lib.mkEnableOption "Store Karakeep dataDir on a ZFS dataset.";

      dataset = lib.mkOption {
        type = lib.types.str;
        default = "dpool/tank/services/karakeep";
      };

      properties = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {
          logbias = "latency";
          recordsize = "16K";
          relatime = "off";
          primarycache = "all";
        };
      };
    };
  };

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
              ${pkgs.coreutils}/bin/install -d -m 0700 -o karakeep -g karakeep ${cfg.dataDir}
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
