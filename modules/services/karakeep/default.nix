{
  config,
  lib,
  pkgs,
  ...
}: let
  homelabCfg = config.homelab;
  cfg = homelabCfg.services.karakeep;
  caddyEnabled = config.services.caddy.enable;

  systemdHelpers = import ../../../lib/systemd-helpers.nix {inherit lib pkgs;};
  permSvc = systemdHelpers.mkPermissionService {
    name = "karakeep";
    inherit (cfg) dataDir;
    user = "karakeep";
    group = "karakeep";
    mainServices = ["karakeep-init" "karakeep-workers" "karakeep-web"];
    zfs = {
      inherit (cfg.zfs) enable;
      datasetServiceName = "zfs-dataset-karakeep";
    };
  };
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

        environmentFile = config.sops.secrets."karakeep/.env".path;

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

    inherit (permSvc) systemd;

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

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [
        cfg.listenPort
      ];
    };
  };
}
